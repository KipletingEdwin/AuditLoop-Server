
require "test_helper"

class AuthTest < ActionDispatch::IntegrationTest
  setup do
    @account = Account.create!(name: "Demo")
    @user = @account.users.create!(email_address: "m@demo.test", password: "password123", role: "manager")
  end

  def login
    post "/auth/login", params: { email_address: "m@demo.test", password: "password123" }, as: :json
    response.parsed_body
  end

  def bearer(token) = { "Authorization" => "Bearer #{token}" }

  test "login returns an access and refresh token" do
    body = login
    assert_response :success
    assert body["access_token"].present?
    assert body["refresh_token"].present?
  end

  test "wrong password is rejected" do
    post "/auth/login", params: { email_address: "m@demo.test", password: "nope" }, as: :json
    assert_response :unauthorized
  end

  test "protected endpoint needs a token" do
    get "/auth/me"
    assert_response :unauthorized
  end

  test "valid access token reaches protected endpoint" do
    get "/auth/me", headers: bearer(login["access_token"])
    assert_response :success
    assert_equal "m@demo.test", response.parsed_body["email_address"]
  end

  test "expired token is rejected" do
    token = JWT.encode({ sub: @user.id, exp: 1.minute.ago.to_i }, Rails.application.secret_key_base, "HS256")
    get "/auth/me", headers: bearer(token)
    assert_response :unauthorized
  end

  test "token signed with the wrong secret is rejected" do
    token = JWT.encode({ sub: @user.id, exp: 5.minutes.from_now.to_i }, "not-the-secret", "HS256")
    get "/auth/me", headers: bearer(token)
    assert_response :unauthorized
  end

  test "refresh rotates the token and the old one stops working" do
    old = login["refresh_token"]

    post "/auth/refresh", params: { refresh_token: old }, as: :json
    assert_response :success
    assert_not_equal old, response.parsed_body["refresh_token"]

    post "/auth/refresh", params: { refresh_token: old }, as: :json
    assert_response :unauthorized
  end

  test "logout revokes the refresh token" do
    refresh = login["refresh_token"]

    post "/auth/logout", params: { refresh_token: refresh }, as: :json
    assert_response :no_content

    post "/auth/refresh", params: { refresh_token: refresh }, as: :json
    assert_response :unauthorized
  end
end