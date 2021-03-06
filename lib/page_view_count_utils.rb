module PageViewCountUtils
  extend Memoist
  PER_PAGE = 10000

  def update_counts(start_date, end_date, set, temp_set = page_view_type.temp_set)
    current_time = Time.current
    processed_results = 0

    log("processing: {start_date: #{start_date}, end_date: #{end_date}}")
    log("#{total_results(start_date, end_date)} results need processing")

    # work through counts in batches of PER_PAGE
    while processed_results < total_results(start_date, end_date) do
      log("processed_results: #{processed_results}/#{total_results(start_date, end_date)}")

      # get counts
      response = page_views(
        start_date: start_date,
        end_date: end_date,
        per_page: PER_PAGE,
        page_token: processed_results
      )

      results = response["reports"].first["data"]["rows"]

      # increment our counts hash in redis
      $redis.pipelined do
        counts_by_document_number(results) do |document_number, visits|
          $redis.zincrby(temp_set, visits, document_number)
        end
      end

      # increment our processed results count
      processed_results += PER_PAGE
    end

    if total_results(start_date, end_date) > 0
      if set == page_view_type.today_set
        # store a copy of the set each hour for internal analysis
        $redis.zunionstore("#{page_view_type.namespace}:#{Date.current.to_s(:iso)}:#{Time.current.hour}", [temp_set])
        $redis.rename(temp_set, set)
      elsif set == page_view_type.yesterday_set
        $redis.rename(temp_set, set)
        $redis.del(temp_set)
      else
        $redis.zunionstore(page_view_type.historical_set, [temp_set, page_view_type.historical_set])
        $redis.del(temp_set)
      end
    end

    $redis.set page_view_type.current_as_of, current_time
  end


  private

  def log(msg)
    logger.info("[#{Time.current}] #{msg}")
  end

  def logger
    @logger ||= Logger.new("#{Rails.root}/log/google_analytics_api.log")
  end

  # convert the GA response data structure into document_number, count
  def counts_by_document_number(rows)
    rows.each do |row|
      url = row["dimensions"][0]
      count = row["metrics"][0]["values"][0].to_i

      # ignore aggregate dimensions like "(other)"
      # and extract document_number
      document_number = url =~ page_view_type.google_analytics_url_regex ? url.split('/')[page_view_type.document_number_position_index] : nil

      # only record page view data if we have a valid looking document number
      # (e.g. with a '-' in it)
      if document_number && document_number.include?('-')
        yield document_number, count
      end
    end
  end

  def total_results(start_date, end_date)
    page_views(
      page_size: 1,
      start_date: start_date,
      end_date: end_date
    )["reports"].first["data"]["rowCount"].to_i
  end
  memoize :total_results


  def page_views(args={})
    GoogleAnalytics::PageViews.new.counts(
      default_args.merge(args)
    )
  end

  def default_args
    {
      dimension_filters: dimension_filters,
    }
  end

  def dimension_filters
    [
      {
        filters: [
          {
            dimensionName: "ga:pagePath",
            operator: "REGEXP",
            expressions: page_view_type.filter_expressions
          }
        ]
      }
    ]
  end

  def clear_cache
    page_view_type.cache_expiry_urls.each{|url| purge_cache(url) }
  end

end
