require_relative '../common'

describe "master courses - child courses - sync history for teacher" do
  include_context "in-process server selenium tests"

  before :once do
    Account.default.enable_feature!(:master_courses)

    @copy_from = course_factory(:active_all => true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)
    account_admin_user(:active_all => true)

    course_with_teacher(:active_all => true)
    @copy_to = @course
    @sub = @template.add_child_course!(@copy_to)
  end

  def run_master_migration
    @migration = MasterCourses::MasterMigration.start_new_migration!(@template, @admin)
    run_jobs
    @cm = @copy_to.content_migrations.where(:child_subscription_id => @sub).last
  end

  before :each do
    user_session(@teacher)
  end

  it "should show import history to a teacher", priority: "1", test_id: 3208649 do
    assmt = @copy_from.assignments.create!(:title => "assmt", :due_at => 2.days.from_now)
    @template.create_content_tag_for!(assmt, {:restrictions => {:content => true}})
    topic = @copy_from.discussion_topics.create!(:title => "something")
    run_master_migration # run the full export initially

    assmt.update_attributes(:due_at => 3.days.from_now) # updated
    topic.update_attributes(:title => "something new") # updated but won't apply
    topic_to = @copy_to.discussion_topics.first
    topic_to.update_attributes(:title => "something that won't get overwritten")
    page = @copy_from.wiki.wiki_pages.create!(:title => "page") # new object

    run_master_migration # run selective export

    get "/courses/#{@copy_to.id}/##{@cm.notification_link_anchor}"
    wait_for_ajaximations

    rows = ff(".bcs__history-item__change-log-row")
    assmt_row = rows.detect{|r| r.text.include?(assmt.title)}
    expect(assmt_row).to contain_css("svg[name=IconBlueprintLockSolid]")
    expect(assmt_row).to include_text("Updated")
    expect(assmt_row).to include_text("Yes") # change applied

    topic_row = rows.detect{|r| r.text.include?(topic_to.title)}
    expect(topic_row).to contain_css("svg[name=IconBlueprintSolid]")
    expect(topic_row).to include_text("No") # change not applied

    page_row = rows.detect{|r| r.text.include?(page.title)}
    expect(page_row).to include_text("Created")
  end
end
