class IssuesSummaryGraphController < ApplicationController
  unloadable
  include IssuesSummaryGraphHelper
  before_filter :find_projects, :set_tracker_ids, :set_issue_category_ids

  DEFAULT_START_DATE = 6.month.ago

  def show
    @from = params[:from]
    @from = DEFAULT_START_DATE.strftime('%Y-%m-%d') if @from.blank? and request.get?

    @to = params[:to]
    @to = Date.today.strftime('%Y-%m-%d') if @to.blank? and request.get?

    @include_subproject = (params[:include_subproject].blank? ? false : true)

    if params[:closed_status_ids]
      @closed_status_ids = params[:closed_status_ids].map {|id| id.to_i}
    else
      @closed_status_ids = IssueStatus.where(:is_closed => true).map {|status| status.id}
    end

    if params[:version_ids].instance_eval { blank? || include?("-1") }
      @version_ids = @projects.inject([0]) { |ids, project| ids + project.shared_versions.map(&:id) }.uniq
      @selected_versions = [-1]
    else
      @version_ids = @selected_versions = params[:version_ids].map(&:to_i)
    end

    @versions = @projects.collect {|project| project.versions }.flatten
  end

  def summary_graph
    closed_status_ids = (params[:closed_issue_statuses] || []).map {|id| id.to_i}
    version_ids = params[:versions].map {|id| id.to_i}
    image = generate_summary_graph(closed_status_ids, version_ids, params[:from], params[:to])
    respond_to do |format|
      format.png  { send_data(image, :disposition => 'inline', :type => 'image/png', :filename => "summary.png") }
    end
  end

  private
  def find_projects
    project_id = (params[:issue] && params[:issue][:project_id]) || params[:project_id]
    @project = Project.find(project_id)
    @projects = [@project]
    @projects += @project.descendants if to_boolean(params[:include_subproject])
    @versions = @projects.collect{|project| project.versions}.flatten
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def set_tracker_ids
    if params[:tracker_ids].instance_eval { blank? || include?("-1") }
      @tracker_ids = Tracker.joins(:projects).merge(@project.self_and_descendants).uniq.pluck(:id)
      @selected_trackers = [-1]
    else
      @tracker_ids = @selected_trackers = params[:tracker_ids].map(&:to_i)
    end
  end

  def set_issue_category_ids
    if params[:issue_category_ids].instance_eval { blank? || include?("-1") }
      @issue_category_ids = IssueCategory.where(project_id: @project.self_and_descendants).uniq.pluck(:id).unshift(0)
      @selected_issue_categories = [-1]
    else
      @issue_category_ids = @selected_issue_categories = params[:issue_category_ids].map(&:to_i)
    end
  end

  def to_boolean(str)
    return false if str.blank?
    str.to_s == 'true'
  end
end
