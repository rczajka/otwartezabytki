# -*- encoding : utf-8 -*-
class Relic < ActiveRecord::Base
  attr_protected :id, :created_at, :update_at

  belongs_to :place

  # for caching purposes
  belongs_to :commune
  belongs_to :district
  belongs_to :voivodeship

  # validates :place_id, :presence => true

  has_ancestry
  serialize :source

  # versioning
  has_paper_trail :class_name => 'RelicVersion', :on => [:update, :destroy]

  include Tire::Model::Search

  # custom tire callback
  after_save do
    # always update root document
    root.tire.update_index
  end

  # create different index for testing
  index_name("#{Rails.env}-relics")

  settings :number_of_shards => 1,
           :number_of_replicas => 1,
           :analysis => {
             :analyzer => {
               :default => {
                 "type" => "polish",
                 "stopwords" => File.open("#{Rails.root}/vendor/stopwords.txt").readlines.join.gsub(/\s*/, '').split(',')
               }
             }
           }

  mapping do
    with_options :index => 'analyzed', :type => 'string' do |a|
      a.indexes :identification
      a.indexes :streets
      a.indexes :register_number
    end
    with_options :index => :not_analyzed do |na|
      na.indexes :id
      na.indexes :voivodeship_id
      na.indexes :district_id
      na.indexes :commune_id
      na.indexes :place_id
      na.indexes :ancestry
    end
  end
  Tire.configure { logger 'log/elasticsearch.log' }

  class << self

    def reindex objs
      index.delete
      index.create :mappings => tire.mapping_to_hash, :settings => tire.settings
      index.import objs
    end

    def search(params)
      tire.search(load: true, page: params[:page], per_page: 100) do
        location = params[:location].to_s.split('-')

        q1 = (params[:q1].present? ? params[:q1] : '*')
        query do
          boolean do
            must { string q1, default_operator: "AND" }
          end
        end
        # # hack to use missing-filter
        # # http://www.elasticsearch.org/guide/reference/query-dsl/missing-filter.html
        # query_value = self.instance_variable_get("@query").instance_variable_get("@value")
        # query_value[:bool][:must] << { constant_score: { filter: { missing: { field: "ancestry" } } } }

        facet "voivodeships" do
          terms :voivodeship_id, size: 16
        end

        if location.size > 0
          filter :term, voivodeship_id: location[0]
          facet "districts", facet_filter: { term: { voivodeship_id: location[0] } } do
            terms :district_id, size: 10_000
          end
        end

        if location.size > 1
          filter :term, district_id: location[1]
          facet "communes", facet_filter: { term: { district_id: location[1] } } do
            terms :commune_id, size: 10_000
          end
        end

        if location.size > 2
          filter :term, commune_id: location[2]
          facet "places", facet_filter: { term: { commune_id: location[2] } } do
            terms :place_id, size: 10_000
          end
        end

        filter :term, place_id: location[3] if location.size > 3

        sort { by :id, 'asc' }
      end
    end

    def suggester q
      tire.search(load: true, per_page: 20) do
        q1 = q.to_s.gsub(/\W/, '') << '*'
        query do
          boolean do
            must { string q1, default_operator: "AND" }
          end
        end
        # # hack to use missing-filter
        # # http://www.elasticsearch.org/guide/reference/query-dsl/missing-filter.html
        # query_value = self.instance_variable_get("@query").instance_variable_get("@value")
        # query_value[:bool][:must] << { constant_score: { filter: { missing: { field: "ancestry" } } } }

        facet "voivodeships" do
          terms :voivodeship_id, size: 3
        end
        facet "districts" do
          terms :district_id, size: 3
        end
        facet "communes" do
          terms :commune_id, size: 3
        end
        facet "places" do
          terms :place_id, size: 3
        end
        sort { by :id, 'asc' }
      end
    end

  end

  def to_indexed_json
    ids = [:voivodeship_id, :district_id, :commune_id, :place_id].zip(get_parent_ids)
    {
      id: id,
      identification: identification,
      street: street,
      register_number: register_number,
      place_full_name: place.full_name,
      descendants: self.descendants.map(&:to_descendant_json)
    }.merge(Hash[ids]).to_json
  end

  def to_descendant_json
    {
      id: id,
      identification: identification,
      street: street,
      register_number: register_number
    }
  end


  def full_identification
    "#{identification} (#{register_number}) datowanie: #{dating_of_obj}; ulica: #{street}"
  end

  def get_parent_ids
    [voivodeship_id, district_id, commune_id, place_id]
  end

  def next
    last_id = self.class.last.try(:id)
    next_id = self.id + 1
    while next_id <= last_id
      obj = self.class.find_by_id(next_id)
      return obj if obj
      next_id += 1
    end
    nil
  end

  def prev
    first_id = self.class.first.try(:id)
    prev_id = self.id - 1
    while prev_id >= first_id
      obj = self.class.find_by_id(prev_id)
      return obj if obj
      prev_id - 1
    end
    nil
  end

  def find_children
    nrelic = self.next

    if nrelic.group.blank? and nrelic.next.try(:group).present?
      nrelic.parent = self
      nrelic.save
      nrelic = nrelic.next
    end

    while nrelic.number.to_s =~ /1/ and nrelic.group.present?
      nrelic.parent = self
      nrelic.save
      nrelic = nrelic.next
    end
  end

  def place_id=(value)
    self[:place_id] = value
    if self.place
      self.commune_id = self.place.commune.id
      self.district_id = self.place.commune.district.id
      self.voivodeship_id = self.place.commune.district.voivodeship.id
    end
  end

  def commune_id
    return nil unless self.place_id
    self[:commune_id] || self.place.commune.id
  end

  def district_id
    return nil unless self.place_id
    self[:district_id] || self.place.commune.id
  end

  def voivodeship_id
    return nil unless self.place_id
    self[:voivodeship_id] || self.place.commune.district.voivodeship.id
  end

end
