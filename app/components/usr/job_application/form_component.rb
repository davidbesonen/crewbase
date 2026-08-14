# frozen_string_literal: true

class Usr::JobApplication::FormComponent < ApplicationComponent
  option :job
  option :job_application

  def form_scope
    job_application.persisted? ? [ :usr, job_application ] : [ :usr, job, job_application ]
  end

  def submit_label
    job_application.persisted? ? "Update Application" : "Submit Application"
  end

  def question_fields
    Array(job.questions).map(&:to_s).map(&:strip).reject(&:blank?)
  end

  def answer_for(question)
    job_application.question_answers.to_h[question]
  end
end
