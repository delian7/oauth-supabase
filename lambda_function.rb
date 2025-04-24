# frozen_string_literal: true

require 'json'
require_relative 'google_client'
require_relative 'supabase_client'

def lambda_handler(event:, context:) # rubocop:disable Lint/UnusedMethodArgument
  http_method = event['httpMethod']
  query_params = event["queryStringParameters"] || {}
  auth_code = query_params["code"]
  resource = event['resource']

  case http_method
  when 'GET'
    return redirect_to_google_auth_url if resource == '/oauth/google'
    return client_request_response('missing auth code') unless auth_code

    user = GoogleClient.new(auth_code).request_token

    SupabaseClient.new.persist_to_supabase_users(user)

    send_response(user)
  else
    method_not_allowed_response
  end
rescue StandardError => e
  error_response(e)
end

def send_response(data)
  {
    'statusCode' => 200,
    'body' => JSON.generate(data)
  }
end

def method_not_allowed_response
  {
    'statusCode' => 405,
    'body' => JSON.generate({ error: 'Method Not Allowed' })
  }
end

def redirect_to_google_auth_url
  location = "https://accounts.google.com/o/oauth2/auth?" \
    "client_id=#{ENV['GOOGLE_CLIENT_ID']}&" \
    "redirect_uri=https://api.delianpetrov.com/oauth/callback&" \
    "response_type=code&" \
    "scope=#{URI.encode_www_form_component('https://www.googleapis.com/auth/calendar.app.created https://www.googleapis.com/auth/calendar.calendars.readonly openid email profile')}&" \
    "access_type=offline&" \
    "prompt=consent"
  {
    'statusCode' => 302,
    'headers' => {
      'Location' => location
    }
  }
end

def client_request_response(message)
  {
    'statusCode' => 400,
    'body' => { error: message }.to_json
  }
end

def error_response(error)
  {
    'statusCode' => 500,
    'body' => JSON.generate({ error: error.message })
  }
end
