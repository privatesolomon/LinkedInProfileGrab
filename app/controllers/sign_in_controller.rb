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
    redirect_to client.auth_code.authorize_url(:scope => 'r_fullprofile',
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
      response = access_token.get('https://api.linkedin.com/v1/people/~:(id,first-name,last-name,headline,picture-url,industry,summary,specialties,positions:(id,title,summary,start-date,end-date,is-current,company:(id,name,type,size,industry,ticker)),educations:(id,school-name,field-of-study,start-date,end-date,degree,activities,notes),associations,interests,num-recommenders,date-of-birth,publications:(id,title,publisher:(name),authors:(id,name),date,url,summary),patents:(id,title,summary,number,status:(id,name),office:(name),inventors:(id,name),date,url),languages:(id,language:(name),proficiency:(level,name)),skills:(id,skill:(name)),certifications:(id,name,authority:(name),number,start-date,end-date),courses:(id,name,number),recommendations-received:(id,recommendation-type,recommendation-text,recommender),honors-awards,three-current-positions,three-past-positions,volunteer)')

      send_data response.body, :type =>"text/plan", :disposition =>'inline'

      #Print body of response to command line window
      #puts response.body


    end

  end

end


