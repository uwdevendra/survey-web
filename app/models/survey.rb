class Survey < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :auth_key, :allow_nil => true
  validates :expiry_date, :date => { :after => Proc.new { Date.current }}, :if => :expiry_date_changed?
  validates_presence_of :expiry_date
  validate :ensure_survey_to_be_archivable
  validates :description, :length => { :maximum => 1024 }

  has_many :questions, :dependent => :destroy
  has_many :categories, :dependent => :destroy
  has_many :responses, :dependent => :destroy
  has_many :survey_users, :dependent => :destroy
  has_many :participating_organizations, :dependent => :destroy

  scope :finalized, where(:finalized => true)
  scope :none, limit(0)
  scope :not_expired, lambda { where('expiry_date > ?', Date.today) }
  scope :expired, lambda { where('expiry_date < ?', Date.today) }
  scope :with_questions, joins(:questions)
  scope :drafts, where(:finalized => false)
  scope :archived, where(:archived => true)
  scope :unarchived, where(:archived => false)
  scope :most_recent, order('published_on DESC NULLS LAST, created_at DESC')

  before_save :generate_auth_key, :if => Proc.new { |s| s.public? && s.auth_key.blank? }

  attr_accessible :name, :expiry_date, :description, :questions_attributes, :finalized, :public
  accepts_nested_attributes_for :questions

  def self.active
    where(active_arel)
  end

  def self.active_plus(extras)
    where(active_arel.or(extra_arel(extras)))
  end

  def finalize
    self.finalized = true
    questions.update_all(:finalized => true)
    categories.update_all(:finalized => true)
    options.update_all(:finalized => true)
    self.save
  end

  def archive
    self.archived = true
    self.name = "#{name} #{I18n.t('activerecord.attributes.survey.archive')}"
    save
  end

  def user_ids
    self.survey_users.map(&:user_id)
  end

  def ids_for_users_with_responses
    self.responses.pluck("user_id").uniq
  end

  def users_for_organization(access_token, organization_id)
    users = {}
    publishable_users = Organization.publishable_users(access_token, organization_id)
    users[:published], users[:unpublished] = publishable_users.partition do |publishable_user|
      user_ids.include?(publishable_user.id)
    end
    users
  end

  def partitioned_organizations(access_token)
    organizations = Organization.all(access_token, :except => organization_id)
    partitioned_organizations = {}
    partitioned_organizations[:participating], partitioned_organizations[:not_participating] = organizations.partition do |organization|
      participating_organization_ids.include? organization.id
    end
    partitioned_organizations
  end

  def expired?
    expiry_date < Date.today
  end

  def duplicate(options = {})
    transaction do
      survey = self.dup
      survey.finalized = false
      survey.archived = false
      survey.name = "#{name}  #{I18n.t('activerecord.attributes.survey.copied')}"
      survey.organization_id = options[:organization_id] if options[:organization_id]
      survey.public = false
      survey.auth_key = nil
      survey.published_on = nil
      survey.save(:validate => false)
      survey.questions << first_level_questions.map { |question| question.duplicate(survey.id) }
      survey.categories << first_level_categories.map { |category| category.duplicate(survey.id) }
      survey
    end
  end

  def share_with_organizations(organizations)
    organizations.each do |organization_id|
      participating_organizations.create(:organization_id => organization_id)
    end if finalized?
    set_published_on
  end

  def publish
    set_published_on
  end

  def published?
    !participating_organizations.empty? || !survey_users.empty? || public?
  end

  def participating_organization_ids
    self.participating_organizations.map(&:organization_id)
  end

  def first_level_questions
    questions.where(:parent_id => nil, :category_id => nil)
  end

  def first_level_categories
    categories.where(:category_id => nil, :parent_id => nil)
  end

  def first_level_categories_with_questions
    first_level_categories.includes([:questions, :categories]).select { |x| x.has_questions? }
  end

  def first_level_elements
    (first_level_questions + first_level_categories_with_questions).sort_by(&:order_number)
  end

  def elements_in_order_as_json
    first_level_elements.map(&:as_json_with_elements_in_order)
  end

  def ordered_question_tree
    first_level_elements.map(&:ordered_question_tree).flatten
  end

  def options
    Option.where(:question_id => questions.pluck('id'))
  end

  def questions_for_reports
    questions.joins(:answers => :response).where("responses.status = 'complete' AND responses.state = 'clean' AND ((answers.content  <> '' AND answers.content IS NOT NULL) OR
                                              questions.type = 'MultiChoiceQuestion')").uniq
  end

  def complete_responses_count(current_ability)
    responses.accessible_by(current_ability).where(:status => 'complete', :blank => false).count
  end

  def incomplete_responses_count(current_ability)
    responses.accessible_by(current_ability).where(:status => 'incomplete', :blank => false).count
  end

  def responses_count(current_ability)
    responses.accessible_by(current_ability).count
  end

  # def assinged_user_count(access_token)
  #   # self.survey_users.count
  #   User.users_for_ids(access_token, self.ids_for_users_with_responses).count
  # end

  def publicize
    self.public = true
    set_published_on
  end

  def identifier_questions
    identifier_questions = questions.where(:identifier => :true)
    identifier_questions.blank? ? first_level_questions.limit(5).to_a : identifier_questions
  end

  def filename_for_excel
    "#{name.gsub(/\W/, "")} (#{id}) - #{Time.now.strftime("%Y-%m-%d %I.%M.%S%P")}"
  end

  def delete_self_and_associated
    transaction do
      self.marked_for_deletion = true
      self.save
      self.destroy
    end
  end

  def deletable?
    responses.where(:blank => false).empty?
  end

  def reporter
    SurveyReporter.new(self)
  end

  def has_multi_record_categories?
    categories.where(:type => MultiRecordCategory).present?
  end

  def find_or_initialize_answers_for_response(response)
    first_level_elements.map { |element| element.find_or_initialize_answers_for_response(response) }.flatten
  end

  def multi_record_categories
    categories.where(:type => MultiRecordCategory)
  end

  private

  def self.active_arel
    survey = Survey.arel_table
    (
      survey[:expiry_date].gteq(Date.today).
      and(survey[:finalized].eq(true)).
      and(survey[:archived].eq(false))
    )
  end

  def self.extra_arel(extras)
    survey = Survey.arel_table
    survey[:id].in(extras)
  end

  def generate_auth_key
    self.auth_key = SecureRandom.urlsafe_base64
  end

  def set_published_on
    if finalized
      self.published_on ||= Date.today
      self.save
    end
  end

  def ensure_survey_to_be_archivable
    errors.add(:base, :must_not_be_archived) if archived? && archived_was
    errors.add(:base, :finalize_before_archive) if archived? && !finalized?
  end
end
