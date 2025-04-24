require 'net/http'
require 'uri'
require 'json'

class GoogleClient
  # Prepare token request to OAuth provider

  def initialize(auth_code)
    @auth_code = auth_code
  end

  def request_token
    uri = URI("https://oauth2.googleapis.com/token")
    req = Net::HTTP::Post.new(uri)
    req.set_form_data(
      grant_type: 'authorization_code',
      code: @auth_code,
      redirect_uri: 'https://api.delianpetrov.com/oauth/callback',
      client_id: ENV['GOOGLE_CLIENT_ID'],
      client_secret: ENV['GOOGLE_CLIENT_SECRET']
    )

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    token_response = JSON.parse(res.body)

    if res.is_a?(Net::HTTPSuccess)
      access_token = token_response["access_token"]
      refresh_token = token_response["refresh_token"]

      user_info = fetch_user_info(access_token)

      {
        email: user_info["email"],
        access_token: access_token,
        refresh_token: refresh_token,
        source: 'Google'
      }
    else
      {
        statusCode: res.code.to_i,
        body: JSON.generate({ error: token_response["error"] || "Token exchange failed" })
      }
    end
  end

  private

  def fetch_user_info(access_token)
    uri = URI("https://openidconnect.googleapis.com/v1/userinfo")
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{access_token}"

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    JSON.parse(res.body)
  end
end
