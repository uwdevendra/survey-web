class SurveyDashboardController < ApplicationController
  def index
    @survey = Survey.find(params[:survey_id])
    authorize! :view_survey_dashboard, @survey
    @users_with_responses = User.users_for_ids(access_token, @survey.ids_for_users_with_responses).paginate(:page => params[:page], :per_page => 2)
  end

  def show
    @survey = Survey.find(params[:survey_id])
    authorize! :view_survey_dashboard, @survey
    @user_id = params[:id].to_i
  end
end
