class Notifier < ActionMailer::Base
  default :from => "donotreply@mira.lib.tufts.edu"


  def feedback(params)
    @params = params

    return mail(:to => Settings.tdl_feedback_address,
      :from => params[:email],
      :subject => Settings.tdl_feedback_subject).deliver
  end


  def derivatives_failure(params)
    @params = params

    return mail(:to => Settings.derivatives_failure_address,
      :subject => "MIRA derivatives failure for #{params[:pid]}").deliver
  end
end
