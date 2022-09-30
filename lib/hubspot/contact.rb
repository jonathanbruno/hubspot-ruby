class Hubspot::Contact < Hubspot::Resource
  self.id_field = "id"
  self.update_method = "post"

  ALL_PATH                = '/crm/v3/objects/contacts'
  CREATE_PATH             = '/crm/v3/objects/contacts'
  CREATE_OR_UPDATE_PATH   = '/contacts/v1/contact/createOrUpdate/email/:email'
  DELETE_PATH             = '/contacts/v1/contact/vid/:id'
  FIND_PATH               = '/crm/v3/objects/contacts/:id'
  FIND_BY_EMAIL_PATH      = '/contacts/v1/contact/email/:email/profile'
  FIND_BY_USER_TOKEN_PATH = '/contacts/v1/contact/utk/:token/profile'
  MERGE_PATH              = '/contacts/v1/contact/merge-vids/:id/'
  SEARCH_PATH             = '/crm/v3/objects/contacts/search'
  UPDATE_PATH             = '/crm/v3/objects/contacts/:id'

  class << self
    def all(opts = {})
      Hubspot::PagedCollection.new(opts) do |options, offset, limit|
        options.merge!("limit" => limit) if limit.present?
        options.merge!("after" => offset) if offset.present?

        response = Hubspot::Connection.get_json(
          ALL_PATH,
          options
        )

        contacts = response["results"].map { |result| from_result(result) }
        [contacts, response.dig('paging','next','after'), response.dig('paging','next','link').present?]
      end
    end

    def find_by_email(email)
      response = Hubspot::Connection.get_json(FIND_BY_EMAIL_PATH, email: email)
      from_result(response)
    end

    def find(id)
      response = Hubspot::Connection.get_json(FIND_PATH, id: id)
      from_result(response)
    end

    def find_by_user_token(token)
      response = Hubspot::Connection.get_json(FIND_BY_USER_TOKEN_PATH, token: token)
      from_result(response)
    end
    alias_method :find_by_utk, :find_by_user_token

    def create(properties = {})
      request = {
        properties: properties
      }
      response = Hubspot::Connection.post_json(create_path, params: {}, body: request)
      from_result(response)
    end

    def update(id, properties = {})
      request = {
        properties: properties
      }
      response = Hubspot::Connection.patch_json(update_path, params: { id: id, no_parse: true }, body: request)
      from_result(response)
    end

    def create_or_update(email, properties = {})
      request = {
        properties: Hubspot::Utils.hash_to_properties(properties.stringify_keys, key_name: "property")
      }
      response = Hubspot::Connection.post_json(CREATE_OR_UPDATE_PATH, params: {email: email}, body: request)
      from_result(response)
    end

    def search_by_email(email, opts = {})
      page = Hubspot::PagedCollection.new(opts) do |options, offset, limit|
        options.merge!("limit" => limit) if limit.present?
        options.merge!("after" => offset) if offset.present?

        response = Hubspot::Connection.post_json(
          SEARCH_PATH,
          options.merge(
            params: {},
            body: {
              "filterGroups":[
                {
                  "filters": [
                    {
                      "propertyName": "email",
                      "operator": "EQ",
                      "value": email
                    }
                  ]
                }
              ]
            }
          )
        )

        contacts = response["results"].map { |result| from_result(result) }
        contacts
      end
      page.resources
    end

    def search(query, opts = {})
      Hubspot::PagedCollection.new(opts) do |options, offset, limit|
        options.merge!("limit" => limit) if limit.present?
        options.merge!("after" => offset) if offset.present?

        response = Hubspot::Connection.get_json(
          SEARCH_PATH,
          options.merge(q: query)
        )

        contacts = response["results"].map { |result| from_result(result) }
        [contacts, response.dig('paging','next','after'), response.dig('paging','next','link').present?]
      end
    end

    def merge(primary, secondary)
      Hubspot::Connection.post_json(
        MERGE_PATH,
        params: { id: primary.to_i, no_parse: true },
        body: { "vidToMerge" => secondary.to_i }
        )

      true
    end
  end

  def name
    [firstname, lastname].compact.join(' ')
  end

  def merge(contact)
    self.class.merge(@id, contact.to_i)
  end
end
