class SignInController < ApplicationController
  API_KEY = '77f36tj3brzevw' #Your app's API key
  API_SECRET = 'c251qfPJYIuGTWaB' #Your app's API secret
  REDIRECT_URI = 'http://intense-woodland-5704.herokuapp.com/accept' #Redirect users after authentication to this path, ensure that you have set up your routes to handle the callbacks
  STATE = SecureRandom.hex(15) #A unique long string that is not easy to guess

  #Instantiate your OAuth2 client object
  def client
    OAuth2::Client.new(
        API_KEY,
        API_SECRET,
        :authorize_url => "/uas/oauth2/authorization?response_type=code", #LinkedIn's authorization path
        :token_url => "/uas/oauth2/accessToken", #LinkedIn's access token path
        :site => "https://www.linkedin.com"
    )
  end

  def default
    #Redirect your user in order to authenticate
    redirect_to client.auth_code.authorize_url(:scope => 'r_fullprofile r_emailaddress r_network',
                                               :state => STATE,
                                               :redirect_uri => REDIRECT_URI)
  end

  def accept
    #Fetch the 'code' query parameter from the callback
    code = params[:code]
    state = params[:state]

    if !state.eql?(STATE)
      #Reject the request as it may be a result of CSRF
      send_data 'state error', :type =>"text/plan", :disposition =>'inline'
    else
      #Get token object, passing in the authorization code from the previous step
      token = client.auth_code.get_token(code, :redirect_uri => REDIRECT_URI)

      #Use token object to create access token for user
      #Note how we're specifying that the access token be passed in the header of the request
      access_token = OAuth2::AccessToken.new(client, token.token, {
                                                       :mode => :header,
                                                       :header_format => 'Bearer %s'
                                                   })


      #Use the access token to make an authenticated API call
      response = access_token.get('https://api.linkedin.com/v1/people/~')

      send_data 'ok so far', :type =>"text/plan", :disposition =>'inline'

      #Print body of response to command line window
      #puts response.body


    end

  end

end


