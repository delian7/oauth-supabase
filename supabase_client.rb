require 'net/http'
require 'uri'
require 'json'

class SupabaseClient
  def persist_to_supabase_users(record)
    url = URI("https://dgzxmivshyxkmridhggl.supabase.co/rest/v1/users")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request["apikey"] = ENV['SUPABASE_TOKEN']
    request["Content-Type"] = "application/json"
    request.body = record.to_json

    response = http.request(request)
    response
  end
end
