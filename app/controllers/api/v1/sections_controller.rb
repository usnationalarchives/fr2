class Api::V1::SectionsController < ApiController
  def index
    publication_date = Date.parse(params[:conditions][:publication_date][:is])
    sections = []

    Section.all.each do |section|
      sections << {
        :name => section.title,
        :slug => section.slug,
        :highlighted_documents => highlighted_documents(section, publication_date),
      }
    end

    render_json_or_jsonp(sections)

  rescue ArgumentError
    raise ActiveRecord::RecordNotFound
  end

  private

  def highlighted_documents(section, publication_date)
    section.
      highlighted_entries(publication_date).
      limit(6).
      map do |entry|
        {
          :document_number => entry.document_number,
          :html_url => entry_path(entry),
          :curated_title => entry.curated_title,
          :curated_abstract => entry.curated_abstract,
          :photo => entry.lede_photo.present? ? {
            :urls => [
              :navigation => entry.lede_photo.photo.url(:navigation),
              :homepage => entry.lede_photo.photo.url(:homepage),
              :small => entry.lede_photo.photo.url(:small),
              :medium => entry.lede_photo.photo.url(:medium),
              :large => entry.lede_photo.photo.url(:large),
              :full_size => entry.lede_photo.photo.url(:full_size),
            ],
            :credit => {
              :name => entry.lede_photo.credit,
              :url => entry.lede_photo.credit_url,
            }
          } : {}
        }
      end
  end
end