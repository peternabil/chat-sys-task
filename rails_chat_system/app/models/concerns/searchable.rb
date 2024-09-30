module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    mappings do
      indexes :body, type: "text"
      indexes :chat_id, type: "keyword"
    end

    def self.search(query, chat_id)
      params = {
        query: {
          bool: {
            must: [
              {
                match: {
                  body: {
                    query: query,
                    fuzziness: "AUTO",
                  },
                },
              },
            ],
            filter: [
              { term: { chat_id: chat_id } },
            ],
          },
        },
      }

      self.__elasticsearch__.search(params)
    end
  end
end
