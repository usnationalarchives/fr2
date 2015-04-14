require 'ostruct'

class TableOfContentsTransformer
  attr_reader :date

  def initialize(date)
    @date = date.to_date
  end

  def process_agencies(agencies)
    agencies_with_metadata = {agencies: []}
    agencies.each do |agency|
      if agency
        agency_hash = {
          name: agency.name,
          slug: agency.slug,
          url: url_lookup(agency.name),
          see_also: (process_see_also(agency) if agency.children.present?),
          document_categories: process_document_categories(agency)
        }.reject{|key,val| val.nil? }

        agencies_with_metadata[:agencies] << agency_hash
      end
    end
    agencies_with_metadata
  end

  def process_entries_without_agencies(agencies)
    agencies_with_metadata = {agencies: []}
    agencies.group_by(&:agency_names).each do |agency_names, entries|
      agency_stub = create_agency_representation_stub(agency_names.map(&:name).to_sentence)
      agency_hash = {
        name: agency_stub.name,
        slug: agency_stub.slug,
        url: agency_stub.url,
        document_categories: [
          {
            name: "",
            documents: process_document_without_subject(entries)
          }
        ]
      }
      agencies_with_metadata[:agencies] << agency_hash
    end
    agencies_with_metadata
  end

  def agency_hash(agencies, entries_without_agencies)
    if entries_without_agencies.present?
      hsh = process_agencies(agencies)
      process_entries_without_agencies(entries_without_agencies)[:agencies].each do |agency|
        hsh[:agencies] << agency
      end
      hsh
    else
      process_agencies(agencies)
    end
  end

  def url_lookup(agency_name)
    agency_stub = create_agency_representation_stub(agency_name)
    agency_stub.url
  end

  def create_agency_representation_stub(agency_name)
    agency = lookup_agency(agency_name)
    if agency
      agency_representation = OpenStruct.new(name: agency_name, slug: agency.slug, url: agency.url)
    elsif agency_name.empty?
      agency_representation = OpenStruct.new(name: "Other Documents", slug: "other_documents", url: "")
    else
      agency_representation = OpenStruct.new(name: agency_name, slug: agency_name.downcase.gsub(' ','-'), url: '' )
    end
    agency_representation
  end

  def lookup_agency(agency_name)
    agency_alias = AgencyName.find_by_name(agency_name)
    agency_alias.agency if agency_alias
  end

  def process_see_also(agency)
    agency.children.map { |sub_agency|
      {
        name: sub_agency.name,
        slug: sub_agency.slug
      }
    }
  end

  def process_document_categories(agency)
    agency.entries_by_type_and_toc_subject.map do |type, entries_by_toc_subject|
      {
        name: type.pluralize,
        documents: process_documents(entries_by_toc_subject)
      }
    end
  end

  def process_documents(entries_by_toc_subject)
    documents=[]
    entries_by_toc_subject.each do |toc_subject, entries_by_toc_subject|
      if toc_subject.present?
        documents << process_document_with_subject(entries_by_toc_subject)
      else
        documents << process_document_without_subject(entries_by_toc_subject)
      end

    end
    documents.flatten
  end

  def process_document_with_subject(entries_by_toc_subject)
    entries_by_toc_subject.map do |entry|
      {
        subject_1: entry.toc_subject,
        subject_2: entry.toc_doc || entry.title,
        document_numbers: [entry.document_number]
      }
    end
  end

  def process_document_without_subject(entries_by_toc_subject)
    entries_by_toc_subject.map do |entry|
    {
      subject_1: entry.toc_doc || entry.title,
      document_numbers: [entry.document_number]
    }
    end
  end

  private

  def save_file(path, filename, table_of_contents_hash)
    FileUtils.mkdir_p(path)
    File.open "#{path}/#{filename}", 'w' do |f|
      f.write(table_of_contents_hash)
    end
  end

end