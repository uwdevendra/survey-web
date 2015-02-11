class Question < ActiveRecord::Base
  belongs_to :parent, :class_name => Option
  belongs_to :category
  belongs_to :survey
  has_many :answers, :dependent => :destroy

  attr_accessible :content, :mandatory, :image, :type, :survey_id, :order_number,
                    :parent_id, :identifier, :category_id, :private, :finalized,:max_length,:min_value,:max_value

  validates_presence_of :content
  validates_uniqueness_of :order_number, :scope => [:survey_id, :parent_id, :category_id], :allow_nil => true
  validate :ensure_survey_is_draft, :if => :mandatory_changed?
  validate :allow_limited_updates_for_finalized, :if => :finalized?, :on => :update

  after_save :update_image_size!, :if => :image_changed?
  before_destroy do |question|
    return if question.survey_marked_for_deletion?
    !question.finalized?
  end

  delegate :question, :to => :parent, :prefix => true
  delegate :marked_for_deletion?, :to => :survey, :prefix => true

  scope :not_private, where("private IS NOT true")
  scope :finalized, where(:finalized => true)

  mount_uploader :image, ImageUploader

  def image_in_base64
    Base64.encode64(image.thumb.file.read) if image?
  end

  def duplicate(survey_id)
    question = self.dup
    question.survey_id = survey_id
    question.finalized = false
    question.options << options.map { |option| option.duplicate(survey_id) } if self.respond_to? :options
    question.remote_image_url = self.image.url
    question.save(:validate => false)
    Question.find(question.id) # Need to do this to clear the CarrierWave instance variables that got duplicated
  end

  def copy_with_order
    duplicate_question = duplicate(survey_id)
    duplicate_question.order_number += 1
    duplicate_question.save
  end

  def as_json_with_elements_in_order
    self.as_json(:methods => 'type')
  end

  def ordered_question_tree
    [self]
  end

  def options
    []
  end

  def json(opts={})
    return as_json(opts).merge({:options => options.map(&:as_json)}) if respond_to? :options
    return as_json(opts)
  end

  def self.new_question_by_type(type, question_params)
    question_class = type.classify.constantize
    question_class.new(question_params)
  end

  def first_level?
    self.parent == nil && self.category == nil
  end

  def report_data
    []
  end

  def answers_for_reports
    Answer.joins(:response).where("answers.question_id = ? AND responses.status = 'complete' AND responses.state = 'clean'", id)
  end

  def nesting_level
    return parent_question.nesting_level + 1 if parent && parent_question
    return category.nesting_level + 1 if category
    return 1
  end

  def index_of_parent_option
    parent_options = parent_question.options.ascending
    parent_options.index(parent)
  end

  def has_multi_record_ancestor?
    category.try(:is_a?, MultiRecordCategory) || category.try(:has_multi_record_ancestor?) || parent.try(:has_multi_record_ancestor?)
  end

  def reporter
    QuestionReporter.decorate(self)
  end

  def update_image_size!
    if image.present?
      update_column(:photo_file_size, image.file.size + image.thumb.file.size + image.medium.file.size)
    else
      update_column(:photo_file_size, nil)
    end
  end

  def find_or_initialize_answers_for_response(response, options={})
    Answer.where(:response_id => response.id, :question_id => self.id, :record_id => options[:record_id]).first_or_initialize
  end

  protected

  def has_multi_record_ancestor
    has_multi_record_ancestor?
  end

  private

  def ensure_survey_is_draft
    if survey.finalized?
      errors.add(:survey_id, :draft_survey)
    end
  end

  def allow_limited_updates_for_finalized
    allowed_attributes = ['content', 'order_number', 'private', 'identifier', 'image']
    disallowed_attributes = self.changed - allowed_attributes
    disallowed_attributes.each {|attr| errors.add(attr.to_sym, :not_allowed) }
  end
end
