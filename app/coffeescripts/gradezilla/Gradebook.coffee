#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

define [
  'jquery'
  'underscore'
  'Backbone'
  'timezone'
  'jsx/gradezilla/DataLoader'
  'react'
  'react-dom'
  'slickgrid.long_text_editor'
  'compiled/views/KeyboardNavDialog'
  'jst/KeyboardNavDialog'
  'vendor/slickgrid'
  'compiled/api/gradingPeriodsApi'
  'compiled/api/gradingPeriodSetsApi'
  'compiled/util/round'
  'compiled/views/InputFilterView'
  'i18nObj'
  'i18n!gradezilla'
  'compiled/gradezilla/GradebookTranslations'
  'jsx/gradebook/CourseGradeCalculator'
  'jsx/gradebook/EffectiveDueDates'
  'jsx/gradebook/GradingSchemeHelper'
  'jsx/gradebook/shared/helpers/GradeFormatHelper'
  'compiled/userSettings'
  'spin.js'
  'compiled/AssignmentMuter'
  'compiled/gradezilla/AssignmentGroupWeightsDialog'
  'compiled/shared/GradeDisplayWarningDialog'
  'compiled/gradezilla/PostGradesFrameDialog'
  'compiled/gradezilla/SubmissionCell'
  'compiled/util/NumberCompare'
  'compiled/util/natcompare'
  'convert_case'
  'str/htmlEscape'
  'jsx/gradezilla/shared/SetDefaultGradeDialogManager'
  'jsx/gradezilla/default_gradebook/CurveGradesDialogManager'
  'jsx/gradezilla/default_gradebook/apis/GradebookApi'
  'jsx/gradezilla/default_gradebook/slick-grid/CellEditorFactory'
  'jsx/gradezilla/default_gradebook/slick-grid/grid-support'
  'jsx/gradezilla/default_gradebook/constants/studentRowHeaderConstants'
  'jsx/gradezilla/default_gradebook/components/AssignmentColumnHeader'
  'jsx/gradezilla/default_gradebook/components/AssignmentGroupColumnHeader'
  'jsx/gradezilla/default_gradebook/components/AssignmentRowCellPropFactory'
  'jsx/gradezilla/default_gradebook/components/CustomColumnHeader'
  'jsx/gradezilla/default_gradebook/components/StudentColumnHeader'
  'jsx/gradezilla/default_gradebook/components/StudentRowHeader'
  'jsx/gradezilla/default_gradebook/components/TotalGradeColumnHeader'
  'jsx/gradezilla/default_gradebook/components/GradebookMenu'
  'jsx/gradezilla/default_gradebook/components/ViewOptionsMenu'
  'jsx/gradezilla/default_gradebook/components/ActionMenu'
  'jsx/gradezilla/default_gradebook/components/AssignmentGroupFilter'
  'jsx/gradezilla/default_gradebook/components/GradingPeriodFilter'
  'jsx/gradezilla/default_gradebook/components/ModuleFilter'
  'jsx/gradezilla/default_gradebook/components/SectionFilter'
  'jsx/gradezilla/default_gradebook/components/GridColor'
  'jsx/gradezilla/default_gradebook/components/StatusesModal'
  'jsx/gradezilla/default_gradebook/components/SubmissionTray'
  'jsx/gradezilla/default_gradebook/components/GradebookSettingsModal'
  'jsx/gradezilla/default_gradebook/constants/colors'
  'jsx/gradezilla/default_gradebook/stores/StudentDatastore'
  'jsx/gradezilla/SISGradePassback/PostGradesStore'
  'jsx/gradezilla/SISGradePassback/PostGradesApp'
  'jsx/gradezilla/SubmissionStateMap'
  'jsx/gradezilla/shared/DownloadSubmissionsDialogManager'
  'jsx/gradezilla/shared/ReuploadSubmissionsDialogManager'
  'jst/gradezilla/group_total_cell'
  'compiled/gradezilla/GradebookKeyboardNav'
  'jsx/gradezilla/shared/AssignmentMuterDialogManager'
  'jsx/gradezilla/shared/helpers/assignmentHelper'
  'instructure-ui/lib/components/Button'
  'instructure-icons/lib/Solid/IconSettingsSolid'
  'jquery.ajaxJSON'
  'jquery.instructure_date_and_time'
  'jqueryui/dialog'
  'jqueryui/tooltip'
  'compiled/behaviors/tooltip'
  'compiled/behaviors/activate'
  'jquery.instructure_misc_helpers'
  'jquery.instructure_misc_plugins'
  'vendor/jquery.ba-tinypubsub'
  'jqueryui/position'
  'jqueryui/sortable'
  'compiled/jquery.kylemenu'
  'compiled/jquery/fixDialogButtons'
  'jsx/context_cards/StudentContextCardTrigger'
], ($, _, Backbone, tz, DataLoader, React, ReactDOM, LongTextEditor, KeyboardNavDialog, KeyboardNavTemplate, Slick,
  GradingPeriodsApi, GradingPeriodSetsApi, round, InputFilterView, i18nObj, I18n, GRADEBOOK_TRANSLATIONS,
  CourseGradeCalculator, EffectiveDueDates, GradingSchemeHelper, GradeFormatHelper, UserSettings, Spinner, AssignmentMuter,
  AssignmentGroupWeightsDialog, GradeDisplayWarningDialog, PostGradesFrameDialog,
  SubmissionCell, NumberCompare, natcompare, ConvertCase, htmlEscape, SetDefaultGradeDialogManager,
  CurveGradesDialogManager, GradebookApi, CellEditorFactory, GridSupport, studentRowHeaderConstants, AssignmentColumnHeader,
  AssignmentGroupColumnHeader, AssignmentRowCellPropFactory, CustomColumnHeader, StudentColumnHeader, StudentRowHeader,
  TotalGradeColumnHeader, GradebookMenu, ViewOptionsMenu, ActionMenu, AssignmentGroupFilter, GradingPeriodFilter, ModuleFilter, SectionFilter,
  GridColor, StatusesModal, SubmissionTray, GradebookSettingsModal, { statusColors }, StudentDatastore, PostGradesStore, PostGradesApp,
  SubmissionStateMap,
  DownloadSubmissionsDialogManager,ReuploadSubmissionsDialogManager, GroupTotalCellTemplate, GradebookKeyboardNav,
  AssignmentMuterDialogManager, assignmentHelper, { default: Button }, { default: IconSettingsSolid }) ->

  isAdmin = =>
    _.contains(ENV.current_user_roles, 'admin')

  IS_ADMIN = isAdmin()

  renderComponent = (reactClass, mountPoint, props = {}, children = null) ->
    component = React.createElement(reactClass, props, children)
    ReactDOM.render(component, mountPoint)

  ## Gradebook Display Settings
  getInitialGridDisplaySettings = (settings, colors) ->
    selectedPrimaryInfo = settings.student_column_display_as || studentRowHeaderConstants.defaultPrimaryInfo

    # in case of no user preference, determine the default value after @hasSections has resolved
    selectedSecondaryInfo = settings.student_column_secondary_info

    sortRowsByColumnId = settings.sort_rows_by_column_id || 'student'
    sortRowsBySettingKey = settings.sort_rows_by_setting_key || 'sortable_name'
    sortRowsByDirection = settings.sort_rows_by_direction || 'ascending'

    filterColumnsBy =
      assignmentGroupId: null
      contextModuleId: null
      gradingPeriodId: null

    if settings.filter_columns_by?
      Object.assign(filterColumnsBy, ConvertCase.camelize(settings.filter_columns_by))

    filterRowsBy =
      sectionId: null

    if settings.filter_rows_by?
      Object.assign(filterRowsBy, ConvertCase.camelize(settings.filter_rows_by))

    {
      colors
      filterColumnsBy
      filterRowsBy
      selectedPrimaryInfo
      selectedSecondaryInfo
      sortRowsBy:
        columnId: sortRowsByColumnId # the column controlling the sort
        settingKey: sortRowsBySettingKey # the key describing the sort criteria
        direction: sortRowsByDirection # the direction of the sort
      selectedViewOptionsFilters: settings.selected_view_options_filters || []
      showEnrollments:
        concluded: false
        inactive: false
      showUnpublishedDisplayed: false
      submissionTray:
        open: false
        studentId: null
        assignmentId: null
    }

  ## Gradebook Application State
  getInitialContentLoadStates = ->
    {
      assignmentsLoaded: false
      contextModulesLoaded: false
      studentsLoaded: false
      submissionsLoaded: false
      teacherNotesColumnUpdating: false
    }

  getInitialCourseContent = () ->
    {
      contextModules: []
    }

  class Gradebook
    columnWidths =
      assignment:
        min: 10
        default_max: 200
        max: 400
      assignmentGroup:
        min: 35
        default_max: 200
        max: 400
      total:
        min: 95
        max: 110

    hasSections: $.Deferred()
    gridReady: $.Deferred()

    constructor: (@options) ->
      # emitted by AssignmentGroupWeightsDialog
      $.subscribe 'assignment_group_weights_changed', @handleAssignmentGroupWeightChange

      $.subscribe 'assignment_muting_toggled',        @handleAssignmentMutingChange
      $.subscribe 'submissions_updated',              @updateSubmissionsFromExternal

      # emitted by SectionMenuView; also subscribed in OutcomeGradebookView
      $.subscribe 'currentSection/change',            @updateCurrentSection

      # emitted by GradingPeriodMenuView
      $.subscribe 'currentGradingPeriod/change',      @updateCurrentGradingPeriod

      @setInitialState()
      @loadSettings()

    # End of constructor

    setInitialState: =>
      @courseContent = getInitialCourseContent()
      @gridDisplaySettings = getInitialGridDisplaySettings(@options.settings, @options.colors)
      @contentLoadStates = getInitialContentLoadStates()
      @headerComponentRefs = {}

      @students = {}
      @studentViewStudents = {}
      @courseContent.students = new StudentDatastore(@students, @studentViewStudents)

      @rows = []

      @initPostGradesStore()
      @initPostGradesLtis()
      @checkForUploadComplete()

    loadSettings: ->
      if @options.grading_period_set
        @gradingPeriodSet = GradingPeriodSetsApi.deserializeSet(@options.grading_period_set)
      else
        @gradingPeriodSet = null
      @assignmentsToHide = UserSettings.contextGet('hidden_columns') || []
      @show_attendance = !!UserSettings.contextGet 'show_attendance'
      @include_ungraded_assignments = UserSettings.contextGet 'include_ungraded_assignments'
      # preferences serialization causes these to always come
      # from the database as strings
      if @options.course_is_concluded || @options.settings.show_concluded_enrollments == 'true'
        @toggleEnrollmentFilter('concluded', true)
      if @options.settings.show_inactive_enrollments == 'true'
        @toggleEnrollmentFilter('inactive', true)
      @initShowUnpublishedAssignments(@options.settings.show_unpublished_assignments)
      @initSubmissionStateMap()
      @gradebookColumnSizeSettings = @options.gradebook_column_size_settings
      @gradebookColumnOrderSettings = @options.gradebook_column_order_settings
      @teacherNotesNotYetLoaded = !@options.teacher_notes? || @options.teacher_notes.hidden

      @gotSections(@options.sections)
      @hasSections.then () =>
        if !@getSelectedSecondaryInfo()
          if @sections_enabled
            @gridDisplaySettings.selectedSecondaryInfo = 'section'
          else
            @gridDisplaySettings.selectedSecondaryInfo = 'none'

    initialize: ->
      @setStudentsLoaded(false)
      @setSubmissionsLoaded(false)

      dataLoader = DataLoader.loadGradebookData(
        courseId: @options.context_id
        perPage: @options.api_max_per_page
        assignmentGroupsURL: @options.assignment_groups_url
        assignmentGroupsParams:
          exclude_response_fields: @fieldsToExcludeFromAssignments
          include: @fieldsToIncludeWithAssignments
        contextModulesURL: @options.context_modules_url
        customColumnsURL: @options.custom_columns_url

        sectionsURL: @options.sections_url

        studentsURL: @options.students_stateless_url
        studentsPageCb: @gotChunkOfStudents
        studentsParams: @studentsParams()
        loadedStudentIds: []

        submissionsURL: @options.submissions_url
        submissionsChunkCb: @gotSubmissionsChunk
        submissionsChunkSize: @options.chunk_size
        customColumnDataURL: @options.custom_column_data_url
        customColumnDataPageCb: @gotCustomColumnDataChunk
        effectiveDueDatesURL: @options.effective_due_dates_url
      )

      dataLoader.gotStudentIds.then (response) =>
        @courseContent.students.setStudentIds(response.user_ids)
        @buildRows()

      $.when(
        dataLoader.gotAssignmentGroups,
        dataLoader.gotEffectiveDueDates
      ).then(@gotAllAssignmentGroupsAndEffectiveDueDates)

      dataLoader.gotCustomColumns.then @gotCustomColumns
      dataLoader.gotStudents.then @gotAllStudents

      @renderedGrid = $.when(
        dataLoader.gotStudentIds,
        dataLoader.gotCustomColumns,
        dataLoader.gotAssignmentGroups,
        dataLoader.gotEffectiveDueDates
      ).then(@doSlickgridStuff)

      dataLoader.gotStudents.then () =>
        @setStudentsLoaded(true)
        @updateColumnHeaders()
        @renderFilters()

      dataLoader.gotAssignmentGroups.then () =>
        @contentLoadStates.assignmentsLoaded = true
        @renderViewOptionsMenu()
        @updateColumnHeaders()

      dataLoader.gotContextModules.then (contextModules) =>
        @setContextModules(contextModules)
        @contentLoadStates.contextModulesLoaded = true
        @renderViewOptionsMenu()

      dataLoader.gotSubmissions.then () =>
        @setSubmissionsLoaded(true)
        @updateColumnHeaders()
        @renderFilters()

    reloadStudentData: =>
      @setStudentsLoaded(false)
      @setSubmissionsLoaded(false)
      @renderFilters()

      dataLoader = DataLoader.loadGradebookData(
        courseId: @options.context_id
        perPage: @options.api_max_per_page
        studentsURL: @options.students_stateless_url
        studentsPageCb: @gotChunkOfStudents
        studentsParams: @studentsParams()
        loadedStudentIds: @courseContent.students.listStudentIds()
        submissionsURL: @options.submissions_url
        submissionsChunkCb: @gotSubmissionsChunk
        submissionsChunkSize: @options.chunk_size
      )

      dataLoader.gotStudentIds.then (response) =>
        @courseContent.students.setStudentIds(response.user_ids)
        @buildRows()

      dataLoader.gotStudents.then () =>
        @setStudentsLoaded(true)
        @updateColumnHeaders()
        @renderFilters()

      dataLoader.gotSubmissions.then () =>
        @setSubmissionsLoaded(true)
        @updateColumnHeaders()
        @renderFilters()

    loadOverridesForSIS: ->
      return unless @options.post_grades_feature

      assignmentGroupsURL = @options.assignment_groups_url.replace('&include%5B%5D=assignment_visibility', '')
      overrideDataLoader = DataLoader.loadGradebookData(
        assignmentGroupsURL: assignmentGroupsURL
        assignmentGroupsParams:
          exclude_response_fields: @fieldsToExcludeFromAssignments
          include: ['overrides']
        onlyLoadAssignmentGroups: true
      )
      $.when(overrideDataLoader.gotAssignmentGroups).then(@addOverridesToPostGradesStore)

    addOverridesToPostGradesStore: (assignmentGroups) =>
      for group in assignmentGroups
        for assignment in group.assignments
          @assignments[assignment.id].overrides = assignment.overrides if @assignments[assignment.id]
      @postGradesStore.setGradeBookAssignments @assignments

    # dependencies - gridReady
    setAssignmentVisibility: (studentIds) ->
      studentsWithHiddenAssignments = []

      for assignmentId, a of @assignments
        if a.only_visible_to_overrides
          hiddenStudentIds = @hiddenStudentIdsForAssignment(studentIds, a)
          for studentId in hiddenStudentIds
            studentsWithHiddenAssignments.push(studentId)
            @updateSubmission assignment_id: assignmentId, user_id: studentId, hidden: true

      for studentId in _.uniq(studentsWithHiddenAssignments)
        student = @student(studentId)
        @calculateStudentGrade(student)

    hiddenStudentIdsForAssignment: (studentIds, assignment) ->
      # TODO: _.difference is ridic expensive.  may need to do something else
      # for large courses with DA (does that happen?)
      _.difference studentIds, assignment.assignment_visibility

    updateAssignmentVisibilities: (hiddenSub) ->
      assignment = @assignments[hiddenSub.assignment_id]
      filteredVisibility = assignment.assignment_visibility.filter (id) -> id != hiddenSub.user_id
      assignment.assignment_visibility = filteredVisibility

    onShow: ->
      $(".post-grades-button-placeholder").show()
      return if @startedInitializing
      @startedInitializing = true

      @spinner = new Spinner() unless @spinner
      $(@spinner.spin().el).css(
        opacity: 0.5
        top: '55px'
        left: '50%'
      ).addClass('use-css-transitions-for-show-hide').appendTo('#main')
      $('#gradebook-grid-wrapper').hide()

    gotCustomColumns: (columns) =>
      @customColumns = columns

    gotCustomColumnDataChunk: (column, columnData) =>
      studentIds = []

      for datum in columnData
        student = @student(datum.user_id)
        if student? #ignore filtered students
          student["custom_col_#{column.id}"] = datum.content
          studentIds.push(student.id)

      @invalidateRowsForStudentIds(_.uniq(studentIds))

    doSlickgridStuff: =>
      @initGrid()
      @initHeader()
      @gridReady.resolve()
      @loadOverridesForSIS()

    gotAllAssignmentGroupsAndEffectiveDueDates: (assignmentGroups, dueDatesResponse) =>
      @effectiveDueDates = dueDatesResponse[0]
      @gotAllAssignmentGroups(assignmentGroups)

    gotAllAssignmentGroups: (assignmentGroups) =>
      @assignmentGroups = {}
      @assignments      = {}
      # purposely passing the @options and assignmentGroups by reference so it can update
      # an assigmentGroup's .group_weight and @options.group_weighting_scheme
      new AssignmentGroupWeightsDialog context: @options, assignmentGroups: assignmentGroups
      for group in assignmentGroups
        @assignmentGroups[group.id] = group
        for assignment in group.assignments
          assignment.assignment_group = group
          assignment.due_at = tz.parse(assignment.due_at)
          assignment.effectiveDueDates = @effectiveDueDates[assignment.id] || {}
          assignment.inClosedGradingPeriod = _.any(assignment.effectiveDueDates, (date) => date.in_closed_grading_period)
          @assignments[assignment.id] = assignment

    gotSections: (sections) =>
      @sections = {}
      for section in sections
        htmlEscape(section)
        @sections[section.id] = section

      @sections_enabled = sections.length > 1
      @hasSections.resolve()

      @postGradesStore.setSections @sections

    gotChunkOfStudents: (students) =>
      for student in students
        student.enrollments = _.filter student.enrollments, @isStudentEnrollment
        isStudentView = student.enrollments[0].type == "StudentViewEnrollment"
        student.sections = student.enrollments.map (e) -> e.course_section_id

        if isStudentView
          @studentViewStudents[student.id] = htmlEscape(student)
        else
          @students[student.id] = htmlEscape(student)

        @updateStudentAttributes(student)
        @updateStudentRow(student)

      @gridReady.then =>
        @setupGrading(students)

      if @isFilteringRowsBySearchTerm()
        # When filtering, students cannot be matched until loaded. The grid must
        # be re-rendered more aggressively to ensure new rows are inserted.
        @buildRows()
      else
        @grid?.render()

    isStudentEnrollment: (e) =>
      e.type == "StudentEnrollment" || e.type == "StudentViewEnrollment"

    setupGrading: (students) =>
      # set up a submission for each student even if we didn't receive one
      @submissionStateMap.setup(students, @assignments)
      for student in students
        for assignment_id, assignment of @assignments
          student["assignment_#{assignment_id}"] ?=
            @submissionStateMap.getSubmission student.id, assignment_id
          submissionState = @submissionStateMap.getSubmissionState(student["assignment_#{assignment_id}"])
          student["assignment_#{assignment_id}"].gradeLocked = submissionState.locked
          student["assignment_#{assignment_id}"].gradingType = assignment.grading_type

        student.initialized = true
        @calculateStudentGrade(student)

      studentIds = _.pluck(students, 'id')
      @setAssignmentVisibility(studentIds)

      @invalidateRowsForStudentIds(studentIds)

    resetGrading: =>
      @initSubmissionStateMap()
      @setupGrading(@courseContent.students.listStudents())

    updateStudentAttributes: (student) =>
      student.computed_current_score ||= 0
      student.computed_final_score ||= 0

      student.isConcluded = _.all student.enrollments, (e) ->
        e.enrollment_state == 'completed'
      student.isInactive = _.all student.enrollments, (e) ->
        e.enrollment_state == 'inactive'

      student.cssClass = "student_#{student.id}"

      @setStudentDisplay(student)

    updateStudentRow: (student) =>
      index = @rows.findIndex (row) => row.id == student.id
      if index != -1
        @rows[index] = student
        @grid?.invalidateRow(index)

    gotAllStudents: =>
      @setStudentsLoaded(true)
      @renderedGrid.then @renderStudentColumnHeader

    studentsThatCanSeeAssignment: (potential_students, assignment) ->
      if assignment.only_visible_to_overrides
        _.pick potential_students, assignment.assignment_visibility...
      else
        potential_students

    isInvalidSort: =>
      sortSettings = @gradebookColumnOrderSettings

      # This course was sorted by a custom column sort at some point but no longer has any stored
      # column order to sort by
      # let's mark it invalid so it reverts to default sort
      return true if sortSettings?.sortType == 'custom' && !sortSettings?.customOrder

      # This course was sorted by module_position at some point but no longer contains modules
      # let's mark it invalid so it reverts to default sort
      return true if sortSettings?.sortType == 'module_position' && @listContextModules().length == 0

      false

    columnOrderHasNotBeenSaved: =>
      !@gradebookColumnOrderSettings

    isDefaultSortOrder: (sortOrder) =>
      not (['due_date', 'name', 'points', 'module_position', 'custom'].includes(sortOrder))

    getStoredSortOrder: =>
      if @isInvalidSort() || @columnOrderHasNotBeenSaved()
        sortType: @defaultSortType
        direction: 'ascending'
      else
        @gradebookColumnOrderSettings

    setStoredSortOrder: (newSortOrder) ->
      @gradebookColumnOrderSettings = newSortOrder
      unless @isInvalidSort()
        url = @options.gradebook_column_order_settings_url
        $.ajaxJSON(url, 'POST', {column_order: newSortOrder})

    onColumnsReordered: =>
      # determine if assignment columns or custom columns were reordered
      # (this works because frozen columns and non-frozen columns are can't be
      # swapped)
      columns = @grid.getColumns()
      currentIds = _(@customColumns).map (c) -> c.id
      reorderedIds = (m[1] for c in columns when m = c.id.match /^custom_col_(\d+)/)

      if !_.isEqual(reorderedIds, currentIds)
        @reorderCustomColumns(reorderedIds)
        .then =>
          colsById = _(@customColumns).indexBy (c) -> c.id
          @customColumns = _(reorderedIds).map (id) -> colsById[id]
      else
        @storeCustomColumnOrder()

      @renderViewOptionsMenu()
      @updateColumnHeaders()

    reorderCustomColumns: (ids) ->
      $.ajaxJSON(@options.reorder_custom_columns_url, "POST", order: ids)

    storeCustomColumnOrder: =>
      newSortOrder =
        sortType: 'custom'
        customOrder: []
      columns = @grid.getColumns()
      scrollable_columns = columns.slice(@getFrozenColumnCount())
      newSortOrder.customOrder = _.pluck(scrollable_columns, 'id')
      @setStoredSortOrder(newSortOrder)

    arrangeColumnsBy: (newSortOrder, isFirstArrangement) =>
      @setStoredSortOrder(newSortOrder) unless isFirstArrangement

      columns = @grid.getColumns()
      frozen = columns.splice(0, @getFrozenColumnCount())
      columns.sort @makeColumnSortFn(newSortOrder)
      columns.splice(0, 0, frozen...)
      @grid.setColumns(columns)

      @renderViewOptionsMenu()
      @updateColumnHeaders()

    makeColumnSortFn: (sortOrder) =>
      switch sortOrder.sortType
        when 'due_date' then @wrapColumnSortFn(@compareAssignmentDueDates, sortOrder.direction)
        when 'module_position' then @wrapColumnSortFn(@compareAssignmentModulePositions, sortOrder.direction)
        when 'name' then @wrapColumnSortFn(@compareAssignmentNames, sortOrder.direction)
        when 'points' then @wrapColumnSortFn(@compareAssignmentPointsPossible, sortOrder.direction)
        when 'custom' then @makeCompareAssignmentCustomOrderFn(sortOrder)
        else @wrapColumnSortFn(@compareAssignmentPositions, sortOrder.direction)

    compareAssignmentPositions: (a, b) ->
      diffOfAssignmentGroupPosition = a.object.assignment_group.position - b.object.assignment_group.position
      diffOfAssignmentPosition = a.object.position - b.object.position

      # order first by assignment_group position and then by assignment position
      # will work when there are less than 1000000 assignments in an assignment_group
      return (diffOfAssignmentGroupPosition * 1000000) + diffOfAssignmentPosition

    compareAssignmentDueDates: (a, b) ->
      firstAssignment = a.object
      secondAssignment = b.object
      assignmentHelper.compareByDueDate(firstAssignment, secondAssignment)

    compareAssignmentModulePositions: (a, b) =>
      firstAssignmentModulePosition = @getContextModule(a.object.module_ids[0])?.position
      secondAssignmentModulePosition = @getContextModule(b.object.module_ids[0])?.position

      if firstAssignmentModulePosition? && secondAssignmentModulePosition?
        if firstAssignmentModulePosition == secondAssignmentModulePosition
          # let's determine their order in the module because both records are in the same module
          firstPositionInModule = a.object.module_positions[0]
          secondPositionInModule = b.object.module_positions[0]

          firstPositionInModule - secondPositionInModule
        else
          # let's determine the order of their modules because both records are in different modules
          firstAssignmentModulePosition - secondAssignmentModulePosition
      else if !firstAssignmentModulePosition? && secondAssignmentModulePosition?
        1
      else if firstAssignmentModulePosition? && !secondAssignmentModulePosition?
        -1
      else
        @compareAssignmentPositions(a, b)

    compareAssignmentNames: (a, b) =>
      @localeSort(a.object.name, b.object.name)

    compareAssignmentPointsPossible: (a, b) ->
      a.object.points_possible - b.object.points_possible

    makeCompareAssignmentCustomOrderFn: (sortOrder) =>
      sortMap = {}
      indexCounter = 0
      for assignmentId in sortOrder.customOrder
        sortMap[String(assignmentId)] = indexCounter
        indexCounter += 1
      return (a, b) =>
        # The second lookup for each index is to maintain backwards
        # compatibility with old gradebook sorting on load which only
        # considered assignment ids.
        aIndex = sortMap[a.id]
        aIndex ?= sortMap[String(a.object.id)] if a.object?
        bIndex = sortMap[b.id]
        bIndex ?= sortMap[String(b.object.id)] if b.object?
        if aIndex? and bIndex?
          return aIndex - bIndex
        # if there's a new assignment or assignment group and its
        # order has not been stored, it should come at the end
        else if aIndex? and not bIndex?
          return -1
        else if bIndex?
          return 1
        else
          return @wrapColumnSortFn(@compareAssignmentPositions)(a, b)

    wrapColumnSortFn: (wrappedFn, direction = 'ascending') ->
      (a, b) ->
        return -1 if b.type is 'total_grade'
        return  1 if a.type is 'total_grade'
        return -1 if b.type is 'assignment_group' and a.type isnt 'assignment_group'
        return  1 if a.type is 'assignment_group' and b.type isnt 'assignment_group'
        if a.type is 'assignment_group' and b.type is 'assignment_group'
          return a.object.position - b.object.position

        [a, b] = [b, a] if direction == 'descending'
        wrappedFn(a, b)

    ## Filtering

    rowFilter: (student) =>
      return true unless @isFilteringRowsBySearchTerm()

      propertiesToMatch = ['name', 'login_id', 'short_name', 'sortable_name']
      pattern = new RegExp(@userFilterTerm, 'i')
      _.any propertiesToMatch, (prop) ->
        student[prop]?.match pattern

    filterAssignmentColumns: (columns) =>
      columnsByAssignmentId = _.indexBy(columns, 'assignmentId')

      assignments = _.pluck(columns, 'object')
      filteredAssignments = @filterAssignments(assignments)

      filteredAssignments.map (assignment) => columnsByAssignmentId[assignment.id]

    filterAssignments: (assignments) =>
      assignmentFilters = [
        @filterAssignmentBySubmissionTypes,
        @filterAssignmentByPublishedStatus,
        @filterAssignmentByAssignmentGroup,
        @filterAssignmentByGradingPeriod,
        @filterAssignmentByModule
      ]

      matchesAllFilters = (assignment) =>
        assignmentFilters.every ((filter) => filter(assignment))

      assignments.filter(matchesAllFilters)

    filterAssignmentBySubmissionTypes: (assignment) =>
      submissionType = '' + assignment.submission_types
      submissionType isnt 'not_graded' and
        (submissionType isnt 'attendance' or @show_attendance)

    filterAssignmentByPublishedStatus: (assignment) =>
      assignment.published or @showUnpublishedAssignments

    filterAssignmentByAssignmentGroup: (assignment) =>
      return true unless @isFilteringColumnsByAssignmentGroup()
      @getAssignmentGroupToShow() == assignment.assignment_group_id

    filterAssignmentByGradingPeriod: (assignment) =>
      return true unless @isFilteringColumnsByGradingPeriod()
      @getGradingPeriodToShow() in @listGradingPeriodsForAssignment(assignment.id)

    filterAssignmentByModule: (assignment) =>
      contextModuleFilterSetting = @getFilterColumnsBySetting('contextModuleId')
      return true unless contextModuleFilterSetting
      # Firefox returns a value of "null" (String) for this when nothing is set.  The comparison
      # to 'null' below is a result of that
      return true if contextModuleFilterSetting == '0' || contextModuleFilterSetting == 'null'

      @getFilterColumnsBySetting('contextModuleId') in (assignment.module_ids || [])

    ## Course Content Event Handlers

    handleAssignmentMutingChange: (assignment) =>
      @renderAssignmentColumnHeader(assignment.id)
      @setAssignmentWarnings()
      @buildRows()

    handleAssignmentGroupWeightChange: (assignment_group_options) =>
      columns = @grid.getColumns()
      for assignment_group in assignment_group_options.assignmentGroups
        column = _.findWhere columns, id: "assignment_group_#{assignment_group.id}"
        @initAssignmentGroupColumnHeader(column)
      @setAssignmentWarnings()
      @grid.setColumns(columns)
      # TODO: don't buildRows?
      @buildRows()

    handleSubmissionsDownloading: (assignmentId) =>
      @getAssignment(assignmentId).hasDownloadedSubmissions = true
      @renderAssignmentColumnHeader(assignmentId)

    # filter, sort, and build the dataset for slickgrid to read from, then
    # force a full redraw
    buildRows: =>
      @rows.length = 0 # empty the list of rows

      for student in @courseContent.students.listStudents()
        if @rowFilter(student)
          @rows.push(student)
          @calculateStudentGrade(student) # TODO: this may not be necessary
          @setStudentDisplay(student) unless student.isPlaceholder

      return unless @grid

      for id, column of @grid.getColumns() when ''+column.object?.submission_types is "attendance"
        column.unselectable = !@show_attendance
        column.cssClass = if @show_attendance then '' else 'completely-hidden'
        @$grid.find("##{@uid}#{column.id}").showIf(@show_attendance)

      @grid.invalidateAllRows()
      @grid.updateRowCount()
      @grid.render()

    setStudentDisplay: (student) =>
      if @sections_enabled
        mySections = (@sections[sectionId].name for sectionId in student.sections when @sections[sectionId])
        sectionNames = $.toSentence(mySections.sort())

      options =
        selectedPrimaryInfo: @getSelectedPrimaryInfo()
        selectedSecondaryInfo: @getSelectedSecondaryInfo()
        sectionNames: sectionNames
        courseId: @options.context_id

      cell = new StudentRowHeader(student, options)
      student.display_name = cell.render()

    gotSubmissionsChunk: (student_submissions) =>
      changedStudentIds = []

      for data in student_submissions
        changedStudentIds.push(data.user_id)
        student = @student(data.user_id)
        for submission in data.submissions
          @updateSubmission(submission)

        student.loaded = true

        @calculateStudentGrade(student)

      # TODO: if gb2 survives long enough, we should consider debouncing all
      # the invalidation/rendering for smoother performance while loading
      @invalidateRowsForStudentIds(_.uniq(changedStudentIds))
      @grid?.render()

    student: (id) =>
      @students[id] || @studentViewStudents[id]

    updateSubmission: (submission) =>
      student = @student(submission.user_id)
      submission.submitted_at = tz.parse(submission.submitted_at)
      submission.grade = GradeFormatHelper.formatGrade(submission.grade, {
        gradingType: submission.gradingType, delocalize: false
      })
      cell = student["assignment_#{submission.assignment_id}"] ||= {}
      _.extend(cell, submission)

    # this is used after the CurveGradesDialog submit xhr comes back.  it does not use the api
    # because there is no *bulk* submissions#update endpoint in the api.
    # It is different from gotSubmissionsChunk in that gotSubmissionsChunk expects an array of students
    # where each student has an array of submissions.  This one just expects an array of submissions,
    # they are not grouped by student.
    updateSubmissionsFromExternal: (submissions) =>
      columns = @grid.getColumns()
      changedColumnHeaders = {}
      changedStudentIds = []

      for submission in submissions
        student = @student(submission.user_id)
        idToMatch = @getAssignmentColumnId(submission.assignment_id)
        cell = index for column, index in columns when column.id is idToMatch

        unless changedColumnHeaders[submission.assignment_id]
          changedColumnHeaders[submission.assignment_id] = cell

        #check for DA visible
        @updateAssignmentVisibilities(submission) unless submission.assignment_visible
        @updateSubmission(submission)
        @submissionStateMap.setSubmissionCellState(student, @assignments[submission.assignment_id], submission)
        submissionState = @submissionStateMap.getSubmissionState(submission)
        student["assignment_#{submission.assignment_id}"].gradeLocked = submissionState.locked
        @calculateStudentGrade(student)
        changedStudentIds.push(student.id)

      for assignmentId of changedColumnHeaders
        @renderAssignmentColumnHeader(assignmentId)

      @updateRowCellsForStudentIds(_.uniq(changedStudentIds))

    cellFormatter: (row, col, submission) =>
      if !@rows[row].loaded or !@rows[row].initialized
        @staticCellFormatter(row, col, '')
      else
        cellAttributes = @submissionStateMap.getSubmissionState(submission)
        if cellAttributes.hideGrade
          @lockedAndHiddenGradeCellFormatter(row, col)
        else
          assignment = @assignments[submission.assignment_id]
          student = @students[submission.user_id]
          formatterOpts =
            isLocked: cellAttributes.locked

          if !assignment?
            @staticCellFormatter(row, col, '')
          else if submission.workflow_state == 'pending_review'
           (SubmissionCell[assignment.grading_type] || SubmissionCell).formatter(row, col, submission, assignment, student, formatterOpts)
          else if assignment.grading_type == 'points' && assignment.points_possible
            SubmissionCell.out_of.formatter(row, col, submission, assignment, student, formatterOpts)
          else
            (SubmissionCell[assignment.grading_type] || SubmissionCell).formatter(row, col, submission, assignment, student, formatterOpts)

    staticCellFormatter: (row, col, val) ->
      "<div class='cell-content gradebook-cell'>#{htmlEscape(val)}</div>"

    lockedAndHiddenGradeCellFormatter: (row, col) ->
      "<div class='cell-content gradebook-cell grayed-out cannot_edit'></div>"

    groupTotalFormatter: (row, col, val, columnDef, student) =>
      return '' unless val?

      percentage = @calculateAndRoundGroupTotalScore val.score, val.possible
      percentage = 0 unless isFinite(percentage)
      possible = round(val.possible, round.DEFAULT)
      possible = if possible then I18n.n(possible) else possible

      if val.possible and @options.grading_standard and columnDef.type is 'total_grade'
        letterGrade = GradingSchemeHelper.scoreToGrade(percentage, @options.grading_standard)

      templateOpts =
        score: I18n.n(round(val.score, round.DEFAULT))
        possible: possible
        letterGrade: letterGrade
        percentage: I18n.n(round(percentage, round.DEFAULT), percentage: true)
      if columnDef.type == 'total_grade'
        templateOpts.warning = @totalGradeWarning
        templateOpts.lastColumn = true
        templateOpts.showPointsNotPercent = @displayPointTotals()
        templateOpts.hideTooltip = @weightedGrades() and not @totalGradeWarning
      GroupTotalCellTemplate templateOpts

    htmlContentFormatter: (row, col, val, columnDef, student) ->
      return '' unless val?
      val

    calculateAndRoundGroupTotalScore: (score, possible_points) ->
      grade = (score / possible_points) * 100
      round(grade, round.DEFAULT)

    submissionsForStudent: (student) =>
      allSubmissions = (value for key, value of student when key.match /^assignment_(?!group)/)
      return allSubmissions unless @gradingPeriodSet?
      return allSubmissions unless @isFilteringColumnsByGradingPeriod()

      _.filter allSubmissions, (submission) =>
        studentPeriodInfo = @effectiveDueDates[submission.assignment_id]?[submission.user_id]
        studentPeriodInfo and studentPeriodInfo.grading_period_id == @getGradingPeriodToShow()

    calculateStudentGrade: (student) =>
      if student.loaded and student.initialized
        hasGradingPeriods = @gradingPeriodSet and @effectiveDueDates

        grades = CourseGradeCalculator.calculate(
          @submissionsForStudent(student),
          @assignmentGroups,
          @options.group_weighting_scheme,
          @gradingPeriodSet if hasGradingPeriods,
          EffectiveDueDates.scopeToUser(@effectiveDueDates, student.id) if hasGradingPeriods
        )

        if @isFilteringColumnsByGradingPeriod()
          grades = grades.gradingPeriods[@getGradingPeriodToShow()]

        finalOrCurrent = if @include_ungraded_assignments then 'final' else 'current'

        for assignmentGroupId, group of @assignmentGroups
          grade = grades.assignmentGroups[assignmentGroupId]
          grade = grade?[finalOrCurrent] || { score: 0, possible: 0, submissions: [] }

          student["assignment_group_#{assignmentGroupId}"] = grade
          for submissionData in grade.submissions
            submissionData.submission.drop = submissionData.drop
        student["total_grade"] = grades[finalOrCurrent]

    ## Grid Styling Methods

    highlightColumn: (event) =>
      $headers = @$grid.find('.slick-header-column')
      return if $headers.filter('.slick-sortable-placeholder').length
      cell = @grid.getCellFromEvent(event)
      col = @grid.getColumns()[cell.cell]
      $headers.filter("##{@uid}#{col.id}").addClass('hovered-column')

    unhighlightColumns: () =>
      @$grid.find('.hovered-column').removeClass('hovered-column')

    minimizeColumn: ($columnHeader) =>
      columnDef = $columnHeader.data('column')
      colIndex = @grid.getColumnIndex(columnDef.id)
      columnDef.cssClass = (columnDef.cssClass || '').replace(' minimized', '') + ' minimized'
      columnDef.unselectable = true
      columnDef.unminimizedName = columnDef.name
      columnDef.name = ''
      columnDef.minimized = true
      @$grid.find(".l#{colIndex}").add($columnHeader).addClass('minimized')
      @assignmentsToHide.push(columnDef.id)
      UserSettings.contextSet('hidden_columns', _.uniq(@assignmentsToHide))

    unminimizeColumn: ($columnHeader) =>
      columnDef = $columnHeader.data('column')
      colIndex = @grid.getColumnIndex(columnDef.id)
      columnDef.cssClass = (columnDef.cssClass || '').replace(' minimized', '')
      columnDef.unselectable = false
      columnDef.name = columnDef.unminimizedName
      columnDef.minimized = false
      @$grid.find(".l#{colIndex}").add($columnHeader).removeClass('minimized')
      $columnHeader.find('.slick-column-name').html($.raw(columnDef.name))
      @assignmentsToHide = $.grep @assignmentsToHide, (el) -> el != columnDef.id
      UserSettings.contextSet('hidden_columns', _.uniq(@assignmentsToHide))

    # this is because of a limitation with SlickGrid,
    # when it makes the header row it does this:
    # $("<div class='slick-header-columns' style='width:10000px; left:-1000px' />")
    # if a course has a ton of assignments then it will not be wide enough to
    # contain them all
    fixMaxHeaderWidth: ->
      @$grid.find('.slick-header-columns').width(1000000)

    # SlickGrid doesn't have a blur event for the grid, so this mimics it in
    # conjunction with a click listener on <body />. When we 'blur' the grid
    # by clicking outside of it, save the current field.
    onGridBlur: (e) =>
      @closeSubmissionTray() if @getSubmissionTrayState().open
      # Prevent exiting the cell editor when clicking in the cell being edited.
      return if @gridSupport.state.getActiveNode()?.contains(e.target)

      # Finish editing
      # * This currently ignores validation, which Gradebook does not use.
      @gridSupport.helper.commitCurrentEdit()

      className = e.target.className

      # PopoverMenu's trigger sends an event with a target whose className is a SVGAnimatedString
      # This normalizes the className where possible
      if typeof className != 'string'
        if typeof className == 'object'
          className = className.baseVal || ''
        else
          className = ''

      # Do nothing if clicking on another cell
      return if className.match(/cell|slick/)

      @gridSupport.state.blur()

    onGridInit: () ->
      tooltipTexts = {}
      # TODO: this "if @spinner" crap is necessary because the outcome
      # gradebook kicks off the gradebook (unnecessarily).  back when the
      # gradebook was slow, this code worked, but now the spinner may never
      # initialize.  fix the way outcome gradebook loads
      $(@spinner.el).remove() if @spinner
      $('#gradebook-grid-wrapper').show()
      @uid = @grid.getUID()
      $('#content').focus ->
        $('#accessibility_warning').removeClass('screenreader-only')
      $('#accessibility_warning').focus ->
        $('#accessibility_warning').blur ->
          $('#accessibility_warning').remove()
      @$grid = grid = $('#gradebook_grid')
        .fillWindowWithMe({
          onResize: => @grid.resizeCanvas()
        })
        .delegate '.slick-cell',
          'mouseenter.gradebook' : @highlightColumn
          'mouseleave.gradebook' : @unhighlightColumns
          'mouseenter' : (event) ->
            grid.find('.hover, .focus').removeClass('hover focus')
            $(this).addClass (if event.type == 'mouseenter' then 'hover' else 'focus')
          'mouseleave' : (event) ->
            $(this).removeClass('hover focus')

      @$grid.addClass('editable') if @options.gradebook_is_editable

      @fixMaxHeaderWidth()
      @grid.onColumnsResized.subscribe (e, data) =>
        @$grid.find('.slick-header-column').each (i, elem) =>
          $columnHeader = $(elem)
          columnDef = $columnHeader.data('column')
          return unless columnDef.type is "assignment"
          if $columnHeader.outerWidth() <= columnWidths.assignment.min
            @minimizeColumn($columnHeader) unless columnDef.minimized
          else if columnDef.minimized
            @unminimizeColumn($columnHeader)

      @keyboardNav = new GradebookKeyboardNav({
        gridSupport: @gridSupport,
        getColumnTypeForColumnId: @getColumnTypeForColumnId,
        toggleDefaultSort: @toggleDefaultSort,
        openSubmissionTray: @openSubmissionTray
      })

      @keyboardNav.init()
      keyBindings = @keyboardNav.keyBindings
      @kbDialog = new KeyboardNavDialog().render(KeyboardNavTemplate({keyBindings}))
      $(document).trigger('gridready')

    sectionList: () ->
      _.values(@sections).sort((a, b) => (a.id - b.id))

    updateSectionFilterVisibility: () ->
      mountPoint = document.getElementById('sections-filter-container')

      if @showSections() and 'sections' in @gridDisplaySettings.selectedViewOptionsFilters
        sectionList = @sectionList()
        props =
          items: sectionList
          onSelect: @updateCurrentSection
          selectedItemId: @getFilterRowsBySetting('sectionId') || '0'
          disabled: !@contentLoadStates.studentsLoaded

        @sectionFilterMenu = renderComponent(SectionFilter, mountPoint, props)
      else if @sectionFilterMenu
        ReactDOM.unmountComponentAtNode(mountPoint)
        @sectionFilterMenu = null

    updateCurrentSection: (sectionId) =>
      sectionId = if sectionId == '0' then null else sectionId
      currentSection = @getFilterRowsBySetting('sectionId')
      if currentSection != sectionId
        @setFilterRowsBySetting('sectionId', sectionId)
        @postGradesStore.setSelectedSection(sectionId)
        @updateSectionFilterVisibility()
        @saveSettings({}, =>
          @reloadStudentData()
        )

    showSections: ->
      @sections_enabled

    assignmentGroupList: ->
      return [] unless @assignmentGroups
      Object.values(@assignmentGroups).sort((a, b) => (a.position - b.position))

    updateAssignmentGroupFilterVisibility: ->
      mountPoint = document.getElementById('assignment-group-filter-container')
      groups = @assignmentGroupList()

      if groups.length > 1 and 'assignmentGroups' in @gridDisplaySettings.selectedViewOptionsFilters
        props =
          items: groups
          onSelect: @updateCurrentAssignmentGroup
          selectedItemId: @getAssignmentGroupToShow()

        @assignmentGroupFilterMenu = renderComponent(AssignmentGroupFilter, mountPoint, props)
      else if @assignmentGroupFilterMenu?
        ReactDOM.unmountComponentAtNode(mountPoint)
        @assignmentGroupFilterMenu = null

    updateCurrentAssignmentGroup: (group) =>
      if @getFilterColumnsBySetting('assignmentGroupId') != group
        @setFilterColumnsBySetting('assignmentGroupId', group)
        @saveSettings()
        @resetGrading()
        @setAssignmentWarnings()
        @updateColumnsAndRenderViewOptionsMenu()
        @updateAssignmentGroupFilterVisibility()

    gradingPeriodList: ->
      @gradingPeriodSet.gradingPeriods.sort((a, b) => (a.startDate - b.startDate))

    updateGradingPeriodFilterVisibility: () ->
      mountPoint = document.getElementById('grading-periods-filter-container')

      if @gradingPeriodSet? and 'gradingPeriods' in @gridDisplaySettings.selectedViewOptionsFilters
        props =
          items: @gradingPeriodList().map((item) => { id: item.id, name: item.title })
          onSelect: @updateCurrentGradingPeriod
          selectedItemId: @getGradingPeriodToShow()

        @gradingPeriodFilterMenu = renderComponent(GradingPeriodFilter, mountPoint, props)
      else if @gradingPeriodFilterMenu?
        ReactDOM.unmountComponentAtNode(mountPoint)
        @gradingPeriodFilterMenu = null

    updateCurrentGradingPeriod: (period) =>
      if @getFilterColumnsBySetting('gradingPeriodId') != period
        @setFilterColumnsBySetting('gradingPeriodId', period)
        @saveSettings()
        @resetGrading()
        @sortGridRows()
        @setAssignmentWarnings()
        @updateColumnsAndRenderViewOptionsMenu()
        @updateGradingPeriodFilterVisibility()

    updateCurrentModule: (moduleId) =>
      if @getFilterColumnsBySetting('contextModuleId') != moduleId
        @setFilterColumnsBySetting('contextModuleId', moduleId)
        @saveSettings()
        @setAssignmentWarnings()
        @updateColumnsAndRenderViewOptionsMenu()
        @updateModulesFilterVisibility()

    moduleList: ->
      @listContextModules().sort((a, b) => (a.position - b.position))

    updateModulesFilterVisibility: () ->
      mountPoint = document.getElementById('modules-filter-container')

      if @listContextModules()?.length > 0 and 'modules' in @gridDisplaySettings.selectedViewOptionsFilters
        props =
          items: @moduleList()
          onSelect: @updateCurrentModule
          selectedItemId: @getFilterColumnsBySetting('contextModuleId') || '0'

        @moduleFilterMenu = renderComponent(ModuleFilter, mountPoint, props)
      else if @moduleFilterMenu?
        ReactDOM.unmountComponentAtNode(mountPoint)
        @moduleFilterMenu = null

    initSubmissionStateMap: =>
      @submissionStateMap = new SubmissionStateMap
        hasGradingPeriods: @gradingPeriodSet?
        selectedGradingPeriodID: @getGradingPeriodToShow()
        isAdmin: isAdmin()

    initPostGradesStore: ->
      @postGradesStore = PostGradesStore
        course:
          id:     @options.context_id
          sis_id: @options.context_sis_id
      @postGradesStore.addChangeListener(@updatePostGradesFeatureButton)

      sectionId = @getFilterRowsBySetting('sectionId')
      @postGradesStore.setSelectedSection(sectionId)

    delayedCall: (delay, fn) =>
      setTimeout fn, delay

    initPostGradesLtis: =>
      @postGradesLtis = @options.post_grades_ltis.map (lti) =>
        postGradesLti =
          id: lti.id
          name: lti.name
          onSelect: =>
            postGradesDialog = new PostGradesFrameDialog
              returnFocusTo: document.querySelector("[data-component='ActionMenu'] button")
              baseUrl: lti.data_url
            @delayedCall 10, => postGradesDialog.open()
            window.external_tool_redirect =
              ready: postGradesDialog.close
              cancel: postGradesDialog.close

    updatePostGradesFeatureButton: =>
      @disablePostGradesFeature = !@postGradesStore.hasAssignments() || !@postGradesStore.selectedSISId()
      @gridReady.then =>
        @renderActionMenu()

    initHeader: =>
      @renderGradebookMenus()
      @renderFilters()

      @arrangeColumnsBy(@getStoredSortOrder(), true)

      @renderGradebookSettingsModal()
      @renderSettingsButton()
      @renderStatusesModal()

      $('#keyboard-shortcuts').click ->
        questionMarkKeyDown = $.Event('keydown', keyCode: 191)
        $(document).trigger(questionMarkKeyDown)

    renderGradebookMenus: =>
      @renderGradebookMenu()
      @renderViewOptionsMenu()
      @renderActionMenu()

    renderGradebookMenu: =>
      mountPoints = document.querySelectorAll('[data-component="GradebookMenu"]')
      props =
        assignmentOrOutcome: @options.assignmentOrOutcome
        courseUrl: ENV.GRADEBOOK_OPTIONS.context_url,
        learningMasteryEnabled: ENV.GRADEBOOK_OPTIONS.outcome_gradebook_enabled,
        navigate: @options.navigate
      for mountPoint in mountPoints
        props.variant = mountPoint.getAttribute('data-variant')
        renderComponent(GradebookMenu, mountPoint, props)

    getTeacherNotesViewOptionsMenuProps: ->
      teacherNotes = @options.teacher_notes
      showingNotes = teacherNotes? and not teacherNotes.hidden
      if showingNotes
        onSelect = => @setTeacherNotesHidden(true)
      else if teacherNotes
        onSelect = => @setTeacherNotesHidden(false)
      else
        onSelect = @createTeacherNotes

      disabled: @contentLoadStates.teacherNotesColumnUpdating
      onSelect: onSelect
      selected: showingNotes

    getColumnSortSettingsViewOptionsMenuProps: ->
      storedSortOrder = @getStoredSortOrder()
      criterion = if @isDefaultSortOrder(storedSortOrder.sortType)
        'default'
      else
        storedSortOrder.sortType

      criterion: criterion
      direction: storedSortOrder.direction || 'ascending'
      disabled: not @contentLoadStates.assignmentsLoaded
      modulesEnabled: @listContextModules().length > 0
      onSortByDefault: =>
        @arrangeColumnsBy({ sortType: 'default', direction: 'ascending' }, false)
      onSortByNameAscending: =>
        @arrangeColumnsBy({ sortType: 'name', direction: 'ascending' }, false)
      onSortByNameDescending: =>
        @arrangeColumnsBy({ sortType: 'name', direction: 'descending' }, false)
      onSortByDueDateAscending: =>
        @arrangeColumnsBy({ sortType: 'due_date', direction: 'ascending' }, false)
      onSortByDueDateDescending: =>
        @arrangeColumnsBy({ sortType: 'due_date', direction: 'descending' }, false)
      onSortByPointsAscending: =>
        @arrangeColumnsBy({ sortType: 'points', direction: 'ascending' }, false)
      onSortByPointsDescending: =>
        @arrangeColumnsBy({ sortType: 'points', direction: 'descending' }, false)
      onSortByModuleAscending: =>
        @arrangeColumnsBy({ sortType: 'module_position', direction: 'ascending' }, false)
      onSortByModuleDescending: =>
        @arrangeColumnsBy({ sortType: 'module_position', direction: 'descending' }, false)

    getFilterSettingsViewOptionsMenuProps: =>
      available: @listAvailableViewOptionsFilters()
      onSelect: (filters) =>
        @setSelectedViewOptionsFilters(filters)
        @renderViewOptionsMenu()
        @renderFilters()
        @saveSettings()
      selected: @listSelectedViewOptionsFilters()

    getViewOptionsMenuProps: ->
      teacherNotes: @getTeacherNotesViewOptionsMenuProps()
      columnSortSettings: @getColumnSortSettingsViewOptionsMenuProps()
      filterSettings: @getFilterSettingsViewOptionsMenuProps()
      showUnpublishedAssignments: @showUnpublishedAssignments
      onSelectShowUnpublishedAssignments: @toggleUnpublishedAssignments
      onSelectShowStatusesModal: =>
        @statusesModal.open()

    renderViewOptionsMenu: =>
      mountPoint = document.querySelector("[data-component='ViewOptionsMenu']")
      @viewOptionsMenu = renderComponent(ViewOptionsMenu, mountPoint, @getViewOptionsMenuProps())

    getActionMenuProps: =>
      focusReturnPoint = document.querySelector("[data-component='ActionMenu'] button")
      actionMenuProps =
        gradebookIsEditable: @options.gradebook_is_editable
        contextAllowsGradebookUploads: @options.context_allows_gradebook_uploads
        gradebookImportUrl: @options.gradebook_import_url
        currentUserId: ENV.current_user_id
        gradebookExportUrl: @options.export_gradebook_csv_url
        postGradesLtis: @postGradesLtis
        postGradesFeature:
          enabled: @options.post_grades_feature? && !@disablePostGradesFeature
          returnFocusTo: focusReturnPoint
          label: @options.sis_name
          store: @postGradesStore
        publishGradesToSis:
          isEnabled: @options.publish_to_sis_enabled?
          publishToSisUrl: @options.publish_to_sis_url

      progressData = @options.gradebook_csv_progress

      if @options.gradebook_csv_progress
        actionMenuProps.lastExport =
          progressId: "#{progressData.progress.id}"
          workflowState: progressData.progress.workflow_state

        attachmentData = @options.attachment
        if attachmentData
          actionMenuProps.attachment =
            id: "#{attachmentData.attachment.id}"
            downloadUrl: @options.attachment_url
            updatedAt: attachmentData.attachment.updated_at
      actionMenuProps

    renderActionMenu: =>
      mountPoint = document.querySelector("[data-component='ActionMenu']")
      props = @getActionMenuProps()
      renderComponent(ActionMenu, mountPoint, props)

    renderFilters: =>
      @updateSectionFilterVisibility()
      @updateAssignmentGroupFilterVisibility()
      @updateGradingPeriodFilterVisibility()
      @updateModulesFilterVisibility()
      @renderSearchFilter()

    renderGridColor: =>
      gridColorMountPoint = document.querySelector('[data-component="GridColor"]')
      gridColorProps =
        colors: @getGridColors()
      renderComponent(GridColor, gridColorMountPoint, gridColorProps)

    renderGradebookSettingsModal: =>
      gradebookSettingsModalMountPoint = document.querySelector("[data-component='GradebookSettingsModal']")
      gradebookSettingsModalProps =
        courseId: @options.context_id
        locale: @options.locale
        onClose: => @gradebookSettingsModalButton.focus()
        newGradebookDevelopmentEnabled: @options.new_gradebook_development_enabled
        gradedLateOrMissingSubmissionsExist: @options.graded_late_or_missing_submissions_exist
      @gradebookSettingsModal = renderComponent(
        GradebookSettingsModal,
        gradebookSettingsModalMountPoint,
        gradebookSettingsModalProps
      )

    renderSettingsButton: =>
      buttonMountPoint = document.getElementById('gradebook-settings-modal-button-container')
      buttonProps =
        id: 'gradebook-settings-button',
        variant: 'icon',
        onClick: @gradebookSettingsModal.open
      iconSettingsSolid = React.createElement(IconSettingsSolid, { title: I18n.t('Gradebook Settings') })
      @gradebookSettingsModalButton = renderComponent(Button, buttonMountPoint, buttonProps, iconSettingsSolid)

    renderStatusesModal: =>
      statusesModalMountPoint = document.querySelector("[data-component='StatusesModal']")
      statusesModalProps =
        onClose: => @viewOptionsMenu.focus()
        colors: @getGridColors()
        afterUpdateStatusColors: @updateGridColors
      @statusesModal = renderComponent(StatusesModal, statusesModalMountPoint, statusesModalProps)

    checkForUploadComplete: () ->
      if UserSettings.contextGet('gradebookUploadComplete')
        $.flashMessage I18n.t('Upload successful')
        UserSettings.contextRemove('gradebookUploadComplete')

    weightedGroups: =>
      @options.group_weighting_scheme == "percent"

    weightedGrades: =>
      @options.group_weighting_scheme == "percent" || @gradingPeriodSet?.weighted || false

    displayPointTotals: =>
      @options.show_total_grade_as_points and not @weightedGrades()

    switchTotalDisplay: ({ dontWarnAgain = false } = {}) =>
      if dontWarnAgain
        UserSettings.contextSet('warned_about_totals_display', true)

      @options.show_total_grade_as_points = not @options.show_total_grade_as_points
      $.ajaxJSON @options.setting_update_url, "PUT", show_total_grade_as_points: @displayPointTotals()
      @grid.invalidate()
      @renderTotalGradeColumnHeader()

    togglePointsOrPercentTotals: (cb) =>
      if UserSettings.contextGet('warned_about_totals_display')
        @switchTotalDisplay()
        cb() if typeof cb == 'function'
      else
        dialog_options =
          showing_points: @options.show_total_grade_as_points
          save: @switchTotalDisplay
          onClose: cb
        new GradeDisplayWarningDialog(dialog_options)

    onUserFilterInput: (term) =>
      @userFilterTerm = term
      @buildRows()

    renderSearchFilter: =>
      unless @userFilter
        @userFilter = new InputFilterView(el: '#search-filter-container input')
        @userFilter.on('input', @onUserFilterInput)

      disabled = !@contentLoadStates.studentsLoaded or !@contentLoadStates.submissionsLoaded
      @userFilter.el.disabled = disabled
      @userFilter.el.setAttribute('aria-disabled', disabled)

    getVisibleGradeGridColumns: ->
      assignmentColumns = @filterAssignmentColumns(@allAssignmentColumns)

      if @gradebookColumnOrderSettings?.sortType
        assignmentColumns.sort @makeColumnSortFn(@getStoredSortOrder())

      scrollableColumns = if @hideAggregateColumns()
        assignmentColumns
      else
        assignmentColumns.concat(@aggregateColumns)

      frozenColumns = @parentColumns.concat(@customColumnDefinitions())
      frozenColumns.concat(scrollableColumns)

    customColumnDefinitions: =>
      @customColumns.map (c) =>
        columnId = @getCustomColumnId(c.id)

        id: columnId
        type: 'custom_column'
        name: htmlEscape c.title
        field: "custom_col_#{c.id}"
        width: 100
        cssClass: "meta-cell custom_column #{columnId}"
        headerCssClass: columnId
        resizable: true
        editor: LongTextEditor
        customColumnId: c.id
        autoEdit: false
        maxLength: 255

    initGrid: =>
      #this is used to figure out how wide to make each column
      $widthTester = $('<span style="padding:10px" />').appendTo('#content')
      testWidth = (text, minWidth, maxWidth) ->
        width = Math.max($widthTester.text(text).outerWidth(), minWidth)
        Math.min width, maxWidth

      @setAssignmentWarnings()

      studentColumnWidth = 150
      if @gradebookColumnSizeSettings
        if @gradebookColumnSizeSettings['student']
          studentColumnWidth = parseInt(@gradebookColumnSizeSettings['student'])

      # Student Column Definition

      @parentColumns = [
        id: 'student'
        type: 'student'
        field: 'display_name'
        width: studentColumnWidth
        cssClass: 'meta-cell primary-column student'
        headerCssClass: 'primary-column student'
        resizable: true
        formatter: @htmlContentFormatter
      ]

      # Assignment Column Definitions

      @allAssignmentColumns = for id, assignment of @assignments
        shrinkForOutOfText = assignment && assignment.grading_type == 'points' && assignment.points_possible?
        minWidth = if shrinkForOutOfText then 140 else 90

        columnId = @getAssignmentColumnId(id)
        fieldName = "assignment_#{id}"

        assignmentWidth = testWidth(assignment.name, minWidth, columnWidths.assignment.default_max)
        if @gradebookColumnSizeSettings && @gradebookColumnSizeSettings[fieldName]
          assignmentWidth = parseInt(@gradebookColumnSizeSettings[fieldName])

        columnDef =
          id: columnId
          field: fieldName
          name: assignment.name
          object: assignment
          formatter: this.cellFormatter
          getGridSupport: => @gridSupport
          propFactory: new AssignmentRowCellPropFactory(assignment, @)
          minWidth: columnWidths.assignment.min
          maxWidth: columnWidths.assignment.max
          width: assignmentWidth
          cssClass: "assignment #{columnId}"
          headerCssClass: columnId
          toolTip: assignment.name
          type: 'assignment'
          assignmentId: assignment.id

        if fieldName in @assignmentsToHide
          columnDef.width = 10
          do (fieldName) =>
            $(document)
              .bind('gridready', =>
                @minimizeColumn(@$grid.find("##{@uid}#{fieldName}"))
              )
              .unbind('gridready.render')
              .bind('gridready.render', => @grid.invalidate() )
        columnDef

      # Assignment Group Column Definitions

      @aggregateColumns = for id, group of @assignmentGroups
        columnId = @getAssignmentGroupColumnId(id)
        fieldName = "assignment_group_#{id}"

        aggregateWidth = testWidth(group.name, columnWidths.assignmentGroup.min, columnWidths.assignmentGroup.default_max)
        if @gradebookColumnSizeSettings && @gradebookColumnSizeSettings[fieldName]
          aggregateWidth = parseInt(@gradebookColumnSizeSettings[fieldName])

        {
          id: columnId
          field: fieldName
          formatter: @groupTotalFormatter
          name: group.name
          toolTip: group.name
          object: group
          minWidth: columnWidths.assignmentGroup.min
          maxWidth: columnWidths.assignmentGroup.max
          width: aggregateWidth
          cssClass: "meta-cell assignment-group-cell #{columnId}"
          headerCssClass: columnId
          type: 'assignment_group'
          assignmentGroupId: group.id
        }

      label = I18n.t "Total"

      totalWidth = testWidth(label, columnWidths.total.min, columnWidths.total.max)
      if @gradebookColumnSizeSettings && @gradebookColumnSizeSettings['total_grade']
        totalWidth = parseInt(@gradebookColumnSizeSettings['total_grade'])

      # Total Grade Column Definition

      total_column =
        id: "total_grade"
        field: "total_grade"
        formatter: @groupTotalFormatter
        toolTip: label
        minWidth: columnWidths.total.min
        maxWidth: columnWidths.total.max
        width: totalWidth
        cssClass: 'total-cell total_grade'
        headerCssClass: 'total_grade'
        type: 'total_grade'

      @aggregateColumns.push total_column

      $widthTester.remove()

      @renderGridColor()
      @createGrid()

    createGrid: () =>
      options = $.extend({
        enableCellNavigation: true
        enableColumnReorder: true
        autoEdit: true # whether to go into edit-mode as soon as you tab to a cell
        editable: @options.gradebook_is_editable
        editorFactory: new CellEditorFactory()
        syncColumnCellResize: true
        rowHeight: 35
        headerHeight: 38
        numberOfColumnsToFreeze: @getFrozenColumnCount()
      }, @options)

      @grid = new Slick.Grid('#gradebook_grid', @rows, @getVisibleGradeGridColumns(), options)
      @grid.setSortColumn('student')

      # This is a faux blur event for SlickGrid.
      # Use capture to preempt SlickGrid's internal handlers.
      document.getElementById('application')
        .addEventListener('click', @onGridBlur, true)

      # Grid Events
      @grid.onKeyDown.subscribe @onGridKeyDown

      # Grid Header Events
      @grid.onHeaderCellRendered.subscribe @onHeaderCellRendered
      @grid.onBeforeHeaderCellDestroy.subscribe @onBeforeHeaderCellDestroy
      @grid.onColumnsReordered.subscribe @onColumnsReordered
      @grid.onColumnsResized.subscribe @onColumnsResized

      # Grid Body Cell Events
      @grid.onBeforeEditCell.subscribe @onBeforeEditCell
      @grid.onCellChange.subscribe @onCellChange

      gridSupportOptions = {
        activeBorderColor: '#1790DF' # $active-border-color
        rows: @rows
      }

      if ENV.use_high_contrast
        gridSupportOptions.activeHeaderBackground = '#E6F1F7' # $ic-bg-light-primary
      else
        gridSupportOptions.activeHeaderBackground = '#E5F2F8' # $ic-bg-light-primary

      # Improved SlickGrid Management
      @gridSupport = new GridSupport(@grid, gridSupportOptions)
      @gridSupport.initialize()

      @gridSupport.events.onActiveLocationChanged.subscribe (event, location) =>
        if location.columnId == 'student' && location.region == 'body'
          @gridSupport.state.getActiveNode().querySelector('.student-grades-link')?.focus()

      @gridSupport.events.onKeyDown.subscribe (event, location) =>
        if (location.region == 'header')
          @getHeaderComponentRef(location.columnId)?.handleKeyDown(event)

      @gridSupport.events.onNavigatePrev.subscribe (event, location) =>
        if (location.region == 'header')
          @getHeaderComponentRef(location.columnId)?.focusAtEnd()

      @gridSupport.events.onNavigateNext.subscribe (event, location) =>
        if (location.region == 'header')
          @getHeaderComponentRef(location.columnId)?.focusAtStart()

      @gridSupport.events.onNavigateLeft.subscribe (event, location) =>
        if (location.region == 'header')
          @getHeaderComponentRef(location.columnId)?.focusAtStart()

      @gridSupport.events.onNavigateRight.subscribe (event, location) =>
        if (location.region == 'header')
          @getHeaderComponentRef(location.columnId)?.focusAtStart()

      @gridSupport.events.onNavigateUp.subscribe (event, location) =>
        if (location.region == 'header')
          @getHeaderComponentRef(location.columnId)?.focusAtStart()

      @onGridInit()

    # Grid Event Handlers

    onGridKeyDown: (event, obj) =>
      return unless obj.row? and obj.cell?

      columns = obj.grid.getColumns()
      column = columns[obj.cell]

      return unless column

      if column.type == 'student' and event.which == 13 # activate link
        event.originalEvent.skipSlickGridDefaults = true

    # Column Header Cell Event Handlers

    onHeaderCellRendered: (event, obj) =>
      if obj.column.type == 'student'
        @renderStudentColumnHeader()
      else if obj.column.type == 'total_grade'
        @renderTotalGradeColumnHeader()
      else if obj.column.type == 'custom_column'
        @renderCustomColumnHeader(obj.column.customColumnId)
      else if obj.column.type == 'assignment'
        @renderAssignmentColumnHeader(obj.column.assignmentId)
      else if obj.column.type == 'assignment_group'
        @renderAssignmentGroupColumnHeader(obj.column.assignmentGroupId)

    onBeforeHeaderCellDestroy: (event, obj) =>
      ReactDOM.unmountComponentAtNode(obj.node)

    ## Grid Body Event Handlers

    # The target cell will enter editing mode
    onBeforeEditCell: (event, obj) =>
      { row, cell } = obj
      $cell = @grid.getCellNode(row, cell)
      return false if $($cell).hasClass("cannot_edit") || $($cell).find(".gradebook-cell").hasClass("cannot_edit")

    # The current cell editor has been changed and is valid
    onCellChange: (event, obj) =>
      { item, column } = obj
      if col_id = column.field.match /^custom_col_(\d+)/
        url = @options.custom_column_datum_url
          .replace(/:id/, col_id[1])
          .replace(/:user_id/, item.id)

        $.ajaxJSON url, "PUT", "column_data[content]": item[column.field]
      else
        # this is the magic that actually updates group and final grades when you edit a cell
        @calculateStudentGrade(item)
        @grid.invalidate()

    onColumnsResized: (event, obj) =>
      grid = obj.grid
      columns = grid.getColumns()

      _.each columns, (column) =>
        if column.previousWidth && column.width != column.previousWidth
          @saveColumnWidthPreference(column.id, column.width)

    # Persisted Gradebook Settings

    saveColumnWidthPreference: (id, newWidth) ->
      url = @options.gradebook_column_size_settings_url
      $.ajaxJSON(url, 'POST', {column_id: id, column_size: newWidth})

    saveSettings: ({
      selectedViewOptionsFilters = @listSelectedViewOptionsFilters(),
      showConcludedEnrollments = @getEnrollmentFilters().concluded,
      showInactiveEnrollments = @getEnrollmentFilters().inactive,
      showUnpublishedAssignments = @showUnpublishedAssignments,
      studentColumnDisplayAs = @getSelectedPrimaryInfo(),
      studentColumnSecondaryInfo = @getSelectedSecondaryInfo(),
      sortRowsBy = @getSortRowsBySetting(),
      colors = @getGridColors()
    } = {}, successFn, errorFn) =>
      selectedViewOptionsFilters.push('') unless selectedViewOptionsFilters.length > 0
      data =
        gradebook_settings:
          filter_columns_by: ConvertCase.underscore(@gridDisplaySettings.filterColumnsBy)
          selected_view_options_filters: selectedViewOptionsFilters
          show_concluded_enrollments: showConcludedEnrollments
          show_inactive_enrollments: showInactiveEnrollments
          show_unpublished_assignments: showUnpublishedAssignments
          student_column_display_as: studentColumnDisplayAs
          student_column_secondary_info: studentColumnSecondaryInfo
          filter_rows_by: ConvertCase.underscore(@gridDisplaySettings.filterRowsBy)
          sort_rows_by_column_id: sortRowsBy.columnId
          sort_rows_by_setting_key: sortRowsBy.settingKey
          sort_rows_by_direction: sortRowsBy.direction
          colors: colors

      # TODO: include the "sort rows by" setting for Assignment Groups and Total
      # Grade when fully supported by the Gradebook `user_ids` endpoint.
      sortingByIncompleteSortFeature = data.gradebook_settings.sort_rows_by_column_id.match(/^assignment_group_/)
      sortingByIncompleteSortFeature ||= data.gradebook_settings.sort_rows_by_column_id == 'total_grade'
      if sortingByIncompleteSortFeature
        delete data.gradebook_settings.sort_rows_by_column_id
        delete data.gradebook_settings.sort_rows_by_setting_key
        delete data.gradebook_settings.sort_rows_by_direction

      $.ajaxJSON(@options.settings_update_url, 'PUT', data, successFn, errorFn)

    ## Grid Sorting Methods

    sortRowsBy: (sortFn) ->
      respectorOfPersonsSort = =>
        if _(@studentViewStudents).size()
          (a, b) =>
            if @studentViewStudents[a.id]
              return 1
            else if @studentViewStudents[b.id]
              return -1
            else
              sortFn(a, b)
        else
          sortFn

      @rows.sort respectorOfPersonsSort()
      @courseContent.students.setStudentIds(_.map(@rows, 'id'))
      @grid?.invalidate()

    getStudentGradeForColumn: (student, field) =>
      student[field] || { score: null, possible: 0 }

    getGradeAsPercent: (grade) =>
      if grade.possible > 0
        (grade.score || 0) / grade.possible
      else
        null

    getColumnTypeForColumnId: (columnId) =>
      if columnId.match /^custom_col/
        return 'custom_column'
      else if columnId.match /^assignment_(?!group)/
        return 'assignment'
      else if columnId.match /^assignment_group/
        return 'assignment_group'
      else
        return columnId

    localeSort: (a, b) ->
      natcompare.strings(a || '', b || '')

    gradeSort: (a, b, field, asc) =>
      scoreForSorting = (student) =>
        grade = @getStudentGradeForColumn(student, field)
        switch
          when field == "total_grade"
            if @options.show_total_grade_as_points
              grade.score
            else
              @getGradeAsPercent(grade)
          when field.match /^assignment_group/
            @getGradeAsPercent(grade)
          else
            # TODO: support assignment grading types
            grade.score

      NumberCompare(scoreForSorting(a), scoreForSorting(b), descending: !asc)

    # when fn is true, those rows get a -1 so they go to the top of the sort
    sortRowsWithFunction: (fn, { asc = true } = {}) ->
      @sortRowsBy((a, b) =>
        [b, a] = [a, b] unless asc
        [rowA, rowB] = [fn(a), fn(b)]
        return -1 if rowA > rowB
        return 1 if rowA < rowB
        @localeSort a.sortable_name, b.sortable_name
      )

    missingSort: (columnId) =>
      @sortRowsWithFunction((row) => !!row[columnId]?.missing)

    lateSort: (columnId) =>
      @sortRowsWithFunction((row) => row[columnId].late)

    sortByStudentColumn: (settingKey, direction) =>
      @sortRowsBy((a, b) =>
        [b, a] = [a, b] unless direction == 'ascending'
        @localeSort(a[settingKey], b[settingKey])
      )

    sortByCustomColumn: (columnId, direction) =>
      @sortRowsBy((a, b) =>
        [b, a] = [a, b] unless direction == 'ascending'
        @localeSort(a[columnId], b[columnId])
      )

    sortByAssignmentColumn: (columnId, settingKey, direction) =>
      switch settingKey
        when 'grade'
          @sortRowsBy((a, b) => @gradeSort(a, b, columnId, direction == 'ascending'))
        when 'late'
          @lateSort(columnId)
        when 'missing'
          @missingSort(columnId)
        # when 'unposted' # TODO: in a future milestone, unposted will be added

    sortByAssignmentGroupColumn: (columnId, settingKey, direction) =>
      if settingKey == 'grade'
        @sortRowsBy((a, b) => @gradeSort(a, b, columnId, direction == 'ascending'))

    sortByTotalGradeColumn: (direction) =>
      @sortRowsBy((a, b) => @gradeSort(a, b, 'total_grade', direction == 'ascending'))

    sortGridRows: =>
      { columnId, settingKey, direction } = @getSortRowsBySetting()
      columnType = @getColumnTypeForColumnId(columnId)

      switch columnType
        when 'custom_column' then @sortByCustomColumn(columnId, direction)
        when 'assignment' then @sortByAssignmentColumn(columnId, settingKey, direction)
        when 'assignment_group' then @sortByAssignmentGroupColumn(columnId, settingKey, direction)
        when 'total_grade' then @sortByTotalGradeColumn(direction)
        else @sortByStudentColumn(settingKey, direction)

      @updateColumnHeaders()

    # show warnings for bad grading setups
    setAssignmentWarnings: =>
      @totalGradeWarning = null

      unorderedAssignments = (assignment for assignmentId, assignment of @assignments)
      filteredAssignments = @filterAssignments(unorderedAssignments)

      if _.any(filteredAssignments, 'muted')
        @totalGradeWarning =
          warningText: I18n.t "This grade differs from the student's view of the grade because some assignments are muted"
          icon: "icon-muted"
      else
        if @weightedGroups()
          # assignment group has 0 points possible
          invalidAssignmentGroups = _.filter @assignmentGroups, (ag) ->
            pointsPossible = _.inject ag.assignments
            , ((sum, a) -> sum + (a.points_possible || 0))
            , 0
            pointsPossible == 0

          for ag in invalidAssignmentGroups
            for a in ag.assignments
              a.invalid = true

          if invalidAssignmentGroups.length > 0
            groupNames = (ag.name for ag in invalidAssignmentGroups)
            text = I18n.t 'invalid_assignment_groups_warning',
              one: "Score does not include %{groups} because it has
                    no points possible"
              other: "Score does not include %{groups} because they have
                      no points possible"
            ,
              groups: $.toSentence(groupNames)
              count: groupNames.length
            @totalGradeWarning =
              warningText: text
              icon: "icon-warning final-warning"

        else
          # no assignments have points possible
          pointsPossible = _.inject filteredAssignments
          , ((sum, a) -> sum + (a.points_possible || 0))
          , 0

          if pointsPossible == 0
            text = I18n.t 'no_assignments_have_points_warning'
            , "Can't compute score until an assignment has points possible"
            @totalGradeWarning =
              warningText: text
              icon: "icon-warning final-warning"

    handleColumnHeaderMenuClose: =>
      @keyboardNav.handleMenuOrDialogClose()

    toggleNotesColumn: (callback) =>
      columnsToReplace = @getFrozenColumnCount()
      callback()
      cols = @grid.getColumns()
      cols.splice 0, columnsToReplace,
        @parentColumns..., @customColumnDefinitions()...
      @grid.setColumns(cols)
      @grid.invalidate()

    showNotesColumn: =>
      if @teacherNotesNotYetLoaded
        @teacherNotesNotYetLoaded = false
        DataLoader.getDataForColumn(@options.teacher_notes, @options.custom_column_data_url, {}, @gotCustomColumnDataChunk)

      @toggleNotesColumn =>
        @customColumns.splice 0, 0, @options.teacher_notes
        @grid.setNumberOfColumnsToFreeze @getFrozenColumnCount()

    getFrozenColumnCount: ->
      @parentColumns.length + @customColumns.length

    hideNotesColumn: =>
      @toggleNotesColumn =>
        for c, i in @customColumns
          if c.teacher_notes
            @customColumns.splice i, 1
            break
        @grid.setNumberOfColumnsToFreeze @getFrozenColumnCount()

    hideAggregateColumns: ->
      return false unless @gradingPeriodSet?
      return false if @gradingPeriodSet.displayTotalsForAllGradingPeriods
      not @isFilteringColumnsByGradingPeriod()

    fieldsToExcludeFromAssignments: ['description', 'needs_grading_count', 'in_closed_grading_period']
    fieldsToIncludeWithAssignments: ['module_ids', 'assignment_group_id']

    studentsParams: ->
      enrollmentStates = ['invited', 'active']

      if @getEnrollmentFilters().concluded
        enrollmentStates.push('completed')
      if @getEnrollmentFilters().inactive
        enrollmentStates.push('inactive')

      { enrollment_state: enrollmentStates }

    ## Grid DOM Access/Reference Methods

    getCustomColumnId: (customColumnId) =>
      "custom_col_#{customColumnId}"

    getAssignmentColumnId: (assignmentId) =>
      "assignment_#{assignmentId}"

    getAssignmentGroupColumnId: (assignmentGroupId) =>
      "assignment_group_#{assignmentGroupId}"

    getColumnHeaderNode: (columnId) =>
      @gridSupport.helper.getColumnHeaderNode(columnId)

    getColumnPositionById: (colId, columnGroup = @grid.getColumns()) ->
      position = null

      columnGroup.forEach (col, idx) ->
        if col.id == colId
          position = idx

      position

    isColumnFrozen: (colId) =>
      columnPosition = @getColumnPositionById(colId, @parentColumns)
      return columnPosition != null

    ## SlickGrid Data Access Methods

    listRows: =>
      @rows # currently the source of truth for filtered and sorted rows

    listRowIndicesForStudentIds: (studentIds) =>
      rowIndicesByStudentId = @listRows().reduce((map, row, index) =>
        map[row.id] = index
        map
      , {})
      studentIds.map (studentId) => rowIndicesByStudentId[studentId]

    ## SlickGrid Update Methods

    updateRowCellsForStudentIds: (studentIds) =>
      return unless @grid

      # Update each row without entirely replacing the DOM elements.
      # This is needed to preserve the editor for the active cell, when present.
      rowIndices = @listRowIndicesForStudentIds(studentIds)
      columns = @grid.getColumns()
      for rowIndex in rowIndices
        for column, columnIndex in columns
          @grid.updateCell(rowIndex, columnIndex)

      null # skip building an unused array return value

    invalidateRowsForStudentIds: (studentIds) =>
      return unless @grid

      rowIndices = @listRowIndicesForStudentIds(studentIds)
      for rowIndex in rowIndices
        @grid.invalidateRow(rowIndex)

      @grid.render()

      null # skip building an unused array return value

    ## Gradebook Bulk UI Update Methods

    updateFrozenColumnsAndRenderGrid: (newColumns = @getVisibleGradeGridColumns()) ->
      @grid.setNumberOfColumnsToFreeze(@getFrozenColumnCount())
      @grid.setColumns(newColumns)
      @grid.invalidate()
      @updateColumnHeaders()

    updateColumnsAndRenderViewOptionsMenu: =>
      @grid.setColumns(@getVisibleGradeGridColumns())
      @updateColumnHeaders()
      @renderViewOptionsMenu()

    ## React Header Component Ref Methods

    setHeaderComponentRef: (columnId, ref) =>
      @headerComponentRefs[columnId] = ref

    getHeaderComponentRef: (columnId) =>
      @headerComponentRefs[columnId]

    removeHeaderComponentRef: (columnId) =>
      delete @headerComponentRefs[columnId]

    ## React Grid Component Rendering Methods

    updateColumnHeaders: ->
      return unless @grid

      for column in @grid.getColumns()
        if column.type == 'custom_column'
          @renderCustomColumnHeader(column.customColumnId)
        if column.type == 'assignment'
          @renderAssignmentColumnHeader(column.assignmentId)
        else if column.type == 'assignment_group'
          @renderAssignmentGroupColumnHeader(column.assignmentGroupId)
        else if column.type == 'total_grade'
          @renderTotalGradeColumnHeader()

      @renderStudentColumnHeader()

    # Column Header Helpers
    handleHeaderKeyDown: (e, columnId) =>
      @gridSupport.navigation.handleHeaderKeyDown e,
        region: 'header'
        cell: @grid.getColumnIndex(columnId)
        columnId: columnId

    # Student Column Header

    getStudentColumnSortBySetting: =>
      columnId = 'student'
      sortRowsBySetting = @getSortRowsBySetting()

      {
        direction: sortRowsBySetting.direction
        disabled: !@contentLoadStates.studentsLoaded
        isSortColumn: sortRowsBySetting.columnId == columnId
        onSortBySortableNameAscending: () =>
          @setSortRowsBySetting(columnId, 'sortable_name', 'ascending')
        onSortBySortableNameDescending: () =>
          @setSortRowsBySetting(columnId, 'sortable_name', 'descending')
        settingKey: sortRowsBySetting.settingKey
      }

    getStudentColumnHeaderProps: ->
      ref: (ref) =>
        @setHeaderComponentRef('student', ref)
      selectedPrimaryInfo: @getSelectedPrimaryInfo()
      onSelectPrimaryInfo: @setSelectedPrimaryInfo
      loginHandleName: @options.login_handle_name
      sisName: @options.sis_name
      selectedSecondaryInfo: @getSelectedSecondaryInfo()
      onSelectSecondaryInfo: @setSelectedSecondaryInfo
      sectionsEnabled: @sections_enabled
      sortBySetting: @getStudentColumnSortBySetting()
      selectedEnrollmentFilters: @getSelectedEnrollmentFilters()
      onToggleEnrollmentFilter: @toggleEnrollmentFilter
      disabled: !@contentLoadStates.studentsLoaded
      addGradebookElement: @keyboardNav.addGradebookElement
      removeGradebookElement: @keyboardNav.removeGradebookElement
      onMenuClose: @handleColumnHeaderMenuClose
      onHeaderKeyDown: (e) =>
        @handleHeaderKeyDown(e, 'student')

    renderStudentColumnHeader: =>
      mountPoint = @getColumnHeaderNode('student')
      props = @getStudentColumnHeaderProps()
      renderComponent(StudentColumnHeader, mountPoint, props)

    # Total Grade Column Header

    freezeTotalGradeColumn: =>
      @totalColumnPositionChanged = true
      allColumns = @grid.getColumns()

      # Remove total_grade column from aggregate section
      totalColumnPosition = @getColumnPositionById('total_grade', @aggregateColumns)
      totalColumn = @aggregateColumns.splice(totalColumnPosition, 1)

      # Remove total_grade column from the current order of displayed columns in the grid
      totalColumnPositionOverall = @getColumnPositionById('total_grade', allColumns)
      allColumns.splice(totalColumnPositionOverall, 1)

      # Add total_grade column next to the position of the student column in the current column order
      studentColumnPositionOverall = @getColumnPositionById('student', allColumns)
      allColumns = allColumns.splice(0, studentColumnPositionOverall + 1).concat(totalColumn).concat(allColumns)

      # Add total_grade column next to the position of the student column in the frozen section
      studentColumnPosition = @getColumnPositionById('student', @parentColumns)
      @parentColumns = @parentColumns.splice(0, studentColumnPosition + 1).concat(totalColumn).concat(@parentColumns)

      @updateFrozenColumnsAndRenderGrid(allColumns)

    moveTotalGradeColumnToEnd: =>
      @totalColumnPositionChanged = true
      allColumns = @grid.getColumns()

      # Remove total_grade column from aggregate or frozen section as needed
      if @isColumnFrozen('total_grade')
        totalColumnPosition = @getColumnPositionById('total_grade', @parentColumns)
        totalColumn = @parentColumns.splice(totalColumnPosition, 1)
      else
        totalColumnPosition = @getColumnPositionById('total_grade', @aggregateColumns)
        totalColumn = @aggregateColumns.splice(totalColumnPosition, 1)

      # Remove total_grade column from the current order of displayed columns in the grid
      totalColumnPositionOverall = @getColumnPositionById('total_grade', allColumns)
      allColumns.splice(totalColumnPositionOverall, 1)

      # Add total_grade column next to the position of the student column in the current column order
      allColumns = allColumns.concat(totalColumn)

      # Add total_grade column to the end of the aggregate section
      @aggregateColumns = @aggregateColumns.concat(totalColumn)

      @updateFrozenColumnsAndRenderGrid(allColumns)

    getTotalGradeColumnSortBySetting: (assignmentId) =>
      columnId = 'total_grade'
      gradeSortDataLoaded =
        @contentLoadStates.assignmentsLoaded and
        @contentLoadStates.studentsLoaded and
        @contentLoadStates.submissionsLoaded
      sortRowsBySetting = @getSortRowsBySetting()

      {
        direction: sortRowsBySetting.direction
        disabled: !gradeSortDataLoaded
        isSortColumn: sortRowsBySetting.columnId == columnId
        onSortByGradeAscending: () =>
          @setSortRowsBySetting(columnId, 'grade', 'ascending')
        onSortByGradeDescending: () =>
          @setSortRowsBySetting(columnId, 'grade', 'descending')
        settingKey: sortRowsBySetting.settingKey
      }

    getTotalGradeColumnGradeDisplayProps: =>
      currentDisplay: if @options.show_total_grade_as_points then 'points' else 'percentage'
      onSelect: @togglePointsOrPercentTotals
      disabled: !@contentLoadStates.submissionsLoaded
      hidden: @weightedGroups()

    getTotalGradeColumnPositionProps: =>
      totalColumnPosition = @getColumnPositionById('total_grade')
      totalIsFrozen = @isColumnFrozen('total_grade')
      backPosition = @grid.getColumns().length - 1

      isInFront: totalIsFrozen
      isInBack: totalColumnPosition == backPosition
      onMoveToFront: =>
        setTimeout(=>
          @freezeTotalGradeColumn()
        , 10)
      onMoveToBack: =>
        setTimeout(=>
          @moveTotalGradeColumnToEnd()
        , 10)

    totalColumnShouldFocus: ->
      if @totalColumnPositionChanged
        @totalColumnPositionChanged = false
        true
      else
        false

    getTotalGradeColumnHeaderProps: ->
      ref: (ref) =>
        @setHeaderComponentRef('total_grade', ref)
      sortBySetting: @getTotalGradeColumnSortBySetting()
      gradeDisplay: @getTotalGradeColumnGradeDisplayProps()
      position: @getTotalGradeColumnPositionProps()
      addGradebookElement: @keyboardNav.addGradebookElement
      removeGradebookElement: @keyboardNav.removeGradebookElement
      onMenuClose: @handleColumnHeaderMenuClose
      grabFocus: @totalColumnShouldFocus()
      onHeaderKeyDown: (e) =>
        @handleHeaderKeyDown(e, 'total_grade')

    renderTotalGradeColumnHeader: =>
      return if @hideAggregateColumns()
      mountPoint = @getColumnHeaderNode('total_grade')
      props = @getTotalGradeColumnHeaderProps()
      renderComponent(TotalGradeColumnHeader, mountPoint, props)

    # Custom Column Header

    getCustomColumnHeaderProps: (customColumnId) =>
      customColumn = _.find(@customColumns, id: customColumnId)
      {
        ref: (ref) =>
          @setHeaderComponentRef(@getCustomColumnId(customColumnId), ref)
        title: customColumn.title
      }

    renderCustomColumnHeader: (customColumnId) =>
      columnId = @getCustomColumnId(customColumnId)
      mountPoint = @getColumnHeaderNode(columnId)
      props = @getCustomColumnHeaderProps(customColumnId)
      renderComponent(CustomColumnHeader, mountPoint, props)

    # Assignment Column Header

    getAssignmentColumnSortBySetting: (assignmentId) =>
      columnId = @getAssignmentColumnId(assignmentId)
      gradeSortDataLoaded =
        @contentLoadStates.assignmentsLoaded and
        @contentLoadStates.studentsLoaded and
        @contentLoadStates.submissionsLoaded
      sortRowsBySetting = @getSortRowsBySetting()

      {
        direction: sortRowsBySetting.direction
        disabled: !gradeSortDataLoaded
        isSortColumn: sortRowsBySetting.columnId == columnId
        onSortByGradeAscending: () =>
          @setSortRowsBySetting(columnId, 'grade', 'ascending')
        onSortByGradeDescending: () =>
          @setSortRowsBySetting(columnId, 'grade', 'descending')
        onSortByLate: () =>
          @setSortRowsBySetting(columnId, 'late', 'ascending')
        onSortByMissing: () =>
          @setSortRowsBySetting(columnId, 'missing', 'ascending')
        onSortByUnposted: () =>
          @setSortRowsBySetting(columnId, 'unposted', 'ascending')
        settingKey: sortRowsBySetting.settingKey
      }

    getAssignmentColumnHeaderProps: (assignmentId) =>
      assignment = @getAssignment(assignmentId)
      assignmentKey = "assignment_#{assignmentId}"
      studentsThatCanSeeAssignment = @studentsThatCanSeeAssignment(@students, assignment)
      contextUrl = ENV.GRADEBOOK_OPTIONS.context_url

      students = _.map studentsThatCanSeeAssignment, (student) =>
        studentRecord =
          id: student.id
          name: student.name
          isInactive: student.isInactive

        submission = student[assignmentKey]
        if submission
          studentRecord.submission =
            score: submission.score
            submittedAt: submission.submitted_at
        else
          studentRecord.submission =
            score: undefined
            submittedAt: undefined

        studentRecord

      downloadSubmissionsManager = new DownloadSubmissionsDialogManager(
        assignment, @options.download_assignment_submissions_url, @handleSubmissionsDownloading
      )
      reuploadSubmissionsManager = new ReuploadSubmissionsDialogManager(
        assignment, @options.re_upload_submissions_url
      )
      curveGradesActionOptions =
        isAdmin: IS_ADMIN
        contextUrl: contextUrl
        submissionsLoaded: @contentLoadStates.submissionsLoaded
      setDefaultGradeDialogManager = new SetDefaultGradeDialogManager(
        assignment, studentsThatCanSeeAssignment, @options.context_id,
        @getFilterRowsBySetting('sectionId'), isAdmin(), @contentLoadStates.submissionsLoaded
      )
      assignmentMuterDialogManager = new AssignmentMuterDialogManager(
        assignment,
        "#{@options.context_url}/assignments/#{assignmentId}/mute",
        @contentLoadStates.submissionsLoaded
      )

      {
        ref: (ref) =>
          @setHeaderComponentRef(@getAssignmentColumnId(assignmentId), ref)
        assignment:
          htmlUrl: assignment.html_url
          id: assignment.id
          invalid: assignment.invalid
          muted: assignment.muted
          name: assignment.name
          omitFromFinalGrade: assignment.omit_from_final_grade
          pointsPossible: assignment.points_possible
          published: assignment.published
          submissionTypes: assignment.submission_types
          courseId: assignment.course_id
          inClosedGradingPeriod: assignment.in_closed_grading_period
        students: students
        submissionsLoaded: @contentLoadStates.submissionsLoaded
        sortBySetting: @getAssignmentColumnSortBySetting(assignmentId)
        curveGradesAction: CurveGradesDialogManager.createCurveGradesAction(
          assignment, studentsThatCanSeeAssignment, curveGradesActionOptions
        )
        setDefaultGradeAction:
          disabled: !setDefaultGradeDialogManager.isDialogEnabled()
          onSelect: setDefaultGradeDialogManager.showDialog
        students: students
        submissionsLoaded: @contentLoadStates.submissionsLoaded
        downloadSubmissionsAction:
          hidden: !downloadSubmissionsManager.isDialogEnabled()
          onSelect: downloadSubmissionsManager.showDialog
        reuploadSubmissionsAction:
          hidden: !reuploadSubmissionsManager.isDialogEnabled()
          onSelect: reuploadSubmissionsManager.showDialog
        muteAssignmentAction:
          disabled: !assignmentMuterDialogManager.isDialogEnabled()
          onSelect: assignmentMuterDialogManager.showDialog
        addGradebookElement: @keyboardNav.addGradebookElement
        removeGradebookElement: @keyboardNav.removeGradebookElement
        onMenuClose: @handleColumnHeaderMenuClose
        showUnpostedMenuItem: @options.new_gradebook_development_enabled
        onHeaderKeyDown: (e) =>
          @handleHeaderKeyDown(e, @getAssignmentColumnId(assignmentId))
      }

    renderAssignmentColumnHeader: (assignmentId) =>
      columnId = @getAssignmentColumnId(assignmentId)
      mountPoint = @getColumnHeaderNode(columnId)
      props = @getAssignmentColumnHeaderProps(assignmentId)
      renderComponent(AssignmentColumnHeader, mountPoint, props)

    # Assignment Group Column Header

    getAssignmentGroupColumnSortBySetting: (assignmentGroupId) =>
      columnId = @getAssignmentGroupColumnId(assignmentGroupId)
      gradeSortDataLoaded =
        @contentLoadStates.assignmentsLoaded and
        @contentLoadStates.studentsLoaded and
        @contentLoadStates.submissionsLoaded
      sortRowsBySetting = @getSortRowsBySetting()

      {
        direction: sortRowsBySetting.direction
        disabled: !gradeSortDataLoaded
        isSortColumn: sortRowsBySetting.columnId == columnId
        onSortByGradeAscending: () =>
          @setSortRowsBySetting(columnId, 'grade', 'ascending')
        onSortByGradeDescending: () =>
          @setSortRowsBySetting(columnId, 'grade', 'descending')
        settingKey: sortRowsBySetting.settingKey
      }

    getAssignmentGroupColumnHeaderProps: (assignmentGroupId) =>
      assignmentGroup = @getAssignmentGroup(assignmentGroupId)
      {
        ref: (ref) =>
          @setHeaderComponentRef(@getAssignmentGroupColumnId(assignmentGroupId), ref)
        assignmentGroup:
          name: assignmentGroup.name
          groupWeight: assignmentGroup.group_weight
        sortBySetting: @getAssignmentGroupColumnSortBySetting(assignmentGroupId)
        weightedGroups: @weightedGroups()
        addGradebookElement: @keyboardNav.addGradebookElement
        removeGradebookElement: @keyboardNav.removeGradebookElement
        onMenuClose: @handleColumnHeaderMenuClose
        onHeaderKeyDown: (e) =>
          @handleHeaderKeyDown(e, @getAssignmentGroupColumnId(assignmentGroupId))
      }

    renderAssignmentGroupColumnHeader: (assignmentGroupId) =>
      columnId = @getAssignmentGroupColumnId(assignmentGroupId)
      mountPoint = @getColumnHeaderNode(columnId)
      props = @getAssignmentGroupColumnHeaderProps(assignmentGroupId)
      renderComponent(AssignmentGroupColumnHeader, mountPoint, props)

    # Submission Tray

    renderSubmissionTray: () =>
      mountPoint = document.getElementById('StudentTray__Container')
      { open, studentId, assignmentId } = @getSubmissionTrayState()
      props =
        key: "submission_tray_#{studentId}_#{assignmentId}"
        isOpen: open
        onRequestClose: @closeSubmissionTray
        onClose: => @gridSupport.helper.focus()
        showContentComingSoon: !@options.new_gradebook_development_enabled
      renderComponent(SubmissionTray, mountPoint, props)

    updateRowAndRenderSubmissionTray: (studentId) =>
      @updateRowCellsForStudentIds([studentId])
      @renderSubmissionTray()

    toggleSubmissionTrayOpen: (studentId, assignmentId) =>
      @setSubmissionTrayState(!@getSubmissionTrayState().open, studentId, assignmentId)
      @updateRowAndRenderSubmissionTray(studentId)

    openSubmissionTray: (studentId, assignmentId) =>
      @setSubmissionTrayState(true, studentId, assignmentId)
      @updateRowAndRenderSubmissionTray(studentId)

    closeSubmissionTray: =>
      @setSubmissionTrayState(false)
      rowIndex = @grid.getActiveCell().row
      studentId = @rows[rowIndex].id
      @updateRowAndRenderSubmissionTray(studentId)

    getSubmissionTrayState: =>
      @gridDisplaySettings.submissionTray

    setSubmissionTrayState: (open, studentId, assignmentId) =>
      @gridDisplaySettings.submissionTray.open = open
      @gridDisplaySettings.submissionTray.studentId = studentId if studentId
      @gridDisplaySettings.submissionTray.assignmentId = assignmentId if assignmentId
      @gridSupport.helper.commitCurrentEdit() if open

    ## Gradebook Application State

    defaultSortType: 'assignment_group'

    ## Gradebook Application State Methods

    initShowUnpublishedAssignments: (show_unpublished_assignments = 'true') =>
      @showUnpublishedAssignments = show_unpublished_assignments == 'true'

    toggleUnpublishedAssignments: =>
      @showUnpublishedAssignments = !@showUnpublishedAssignments
      @updateColumnsAndRenderViewOptionsMenu()

      @saveSettings(
        { @showUnpublishedAssignments },
        () =>, # on success, do nothing since the render happened earlier
        () => # on failure, undo
          @showUnpublishedAssignments = !@showUnpublishedAssignments
          @updateColumnsAndRenderViewOptionsMenu()
      )

    setAssignmentsLoaded: (loaded) =>
      @contentLoadStates.assignmentsLoaded = loaded

    setStudentsLoaded: (loaded) =>
      @contentLoadStates.studentsLoaded = loaded

    setSubmissionsLoaded: (loaded) =>
      @contentLoadStates.submissionsLoaded = loaded

    setTeacherNotesColumnUpdating: (updating) =>
      @contentLoadStates.teacherNotesColumnUpdating = updating

    ## Grid Display Settings Access Methods

    getFilterColumnsBySetting: (filterKey) =>
      @gridDisplaySettings.filterColumnsBy[filterKey]

    setFilterColumnsBySetting: (filterKey, value) =>
      @gridDisplaySettings.filterColumnsBy[filterKey] = value

    getFilterRowsBySetting: (filterKey) =>
      @gridDisplaySettings.filterRowsBy[filterKey]

    setFilterRowsBySetting: (filterKey, value) =>
      @gridDisplaySettings.filterRowsBy[filterKey] = value

    isFilteringColumnsByAssignmentGroup: =>
      @getAssignmentGroupToShow() != '0'

    getAssignmentGroupToShow: () =>
      groupId = @getFilterColumnsBySetting('assignmentGroupId') || '0'
      if groupId in _.pluck(@assignmentGroups, 'id') then groupId else '0'

    isFilteringColumnsByGradingPeriod: =>
      @getGradingPeriodToShow() != '0'

    isFilteringRowsBySearchTerm: =>
      @userFilterTerm? and @userFilterTerm != ''

    getGradingPeriodToShow: () =>
      return '0' unless @gradingPeriodSet?
      periodId = @getFilterColumnsBySetting('gradingPeriodId') || @options.current_grading_period_id
      if periodId in _.pluck(@gradingPeriodSet.gradingPeriods, 'id') then periodId else '0'

    setSelectedPrimaryInfo: (primaryInfo, skipRedraw) =>
      @gridDisplaySettings.selectedPrimaryInfo = primaryInfo
      @saveSettings()
      unless skipRedraw
        @buildRows()
        @renderStudentColumnHeader()

    toggleDefaultSort: (columnId) =>
      sortSettings = @getSortRowsBySetting()
      columnType = @getColumnTypeForColumnId(columnId)
      settingKey = @getDefaultSettingKeyForColumnType(columnType)
      direction = 'ascending'

      if sortSettings.columnId == columnId && sortSettings.settingKey == settingKey && sortSettings.direction == 'ascending'
        direction = 'descending'

      @setSortRowsBySetting(columnId, settingKey, direction)

    getDefaultSettingKeyForColumnType: (columnType) =>
      if columnType == 'assignment' || columnType == 'assignment_group' || columnType == 'total_grade'
        return 'grade'
      else if columnType == 'student'
        return 'sortable_name'

    getSelectedPrimaryInfo: () =>
      @gridDisplaySettings.selectedPrimaryInfo

    setSelectedSecondaryInfo: (secondaryInfo, skipRedraw) =>
      @gridDisplaySettings.selectedSecondaryInfo = secondaryInfo
      @saveSettings()
      unless skipRedraw
        @buildRows()
        @renderStudentColumnHeader()

    getSelectedSecondaryInfo: () =>
      @gridDisplaySettings.selectedSecondaryInfo

    setSortRowsBySetting: (columnId, settingKey, direction) =>
      @gridDisplaySettings.sortRowsBy.columnId = columnId
      @gridDisplaySettings.sortRowsBy.settingKey = settingKey
      @gridDisplaySettings.sortRowsBy.direction = direction
      @saveSettings()
      @sortGridRows()

    getSortRowsBySetting: =>
      @gridDisplaySettings.sortRowsBy

    updateGridColors: (colors, successFn, errorFn) =>
      setAndRenderColors = =>
        @setGridColors(colors)
        @renderGridColor()
        successFn()

      @saveSettings({ colors }, setAndRenderColors, errorFn)

    setGridColors: (colors) =>
      @gridDisplaySettings.colors = colors

    getGridColors: =>
      statusColors @gridDisplaySettings.colors

    listAvailableViewOptionsFilters: =>
      filters = []
      filters.push('assignmentGroups') if Object.keys(@assignmentGroups || {}).length > 1
      filters.push('gradingPeriods') if @gradingPeriodSet?
      filters.push('modules') if @listContextModules().length > 0
      filters.push('sections') if @sections_enabled
      filters

    setSelectedViewOptionsFilters: (filters) =>
      @gridDisplaySettings.selectedViewOptionsFilters = filters

    listSelectedViewOptionsFilters: =>
      @gridDisplaySettings.selectedViewOptionsFilters

    toggleEnrollmentFilter: (enrollmentFilter, skipApply) =>
      @getEnrollmentFilters()[enrollmentFilter] = !@getEnrollmentFilters()[enrollmentFilter]
      @applyEnrollmentFilter() unless skipApply

    applyEnrollmentFilter: () =>
      showInactive = @getEnrollmentFilters().inactive
      showConcluded = @getEnrollmentFilters().concluded
      @saveSettings({ showInactive, showConcluded }, =>
        @renderStudentColumnHeader()
        @reloadStudentData()
      )

    getEnrollmentFilters: () =>
      @gridDisplaySettings.showEnrollments

    getSelectedEnrollmentFilters: () =>
      filters = @getEnrollmentFilters()
      selectedFilters = []
      for filter of filters
        selectedFilters.push filter if filters[filter]
      selectedFilters

    ## Gradebook Content Access Methods

    setAssignments: (assignmentMap) =>
      @assignments = assignmentMap

    setAssignmentGroups: (assignmentGroupMap) =>
      @assignmentGroups = assignmentGroupMap

    getAssignment: (assignmentId) =>
      @assignments[assignmentId]

    getAssignmentGroup: (assignmentGroupId) =>
      @assignmentGroups[assignmentGroupId]

    setContextModules: (contextModules) =>
      @courseContent.contextModules = contextModules
      @courseContent.modulesById = {}

      if contextModules?.length
        for contextModule in contextModules
          @courseContent.modulesById[contextModule.id] = contextModule

      contextModules

    getContextModule: (contextModuleId) =>
      @courseContent.modulesById?[contextModuleId] if contextModuleId?

    listContextModules: =>
      @courseContent.contextModules

    listGradingPeriodsForAssignment: (assignmentId) =>
      effectiveDueDates = @effectiveDueDates[assignmentId] || {}
      _.uniq((effectiveDueDate.grading_period_id for userId, effectiveDueDate of effectiveDueDates))

    ## Gradebook Content Api Methods

    createTeacherNotes: =>
      @setTeacherNotesColumnUpdating(true)
      @renderViewOptionsMenu()
      GradebookApi.createTeacherNotesColumn(@options.context_id)
        .then (response) =>
          @options.teacher_notes = response.data
          @showNotesColumn()
          @setTeacherNotesColumnUpdating(false)
          @renderViewOptionsMenu()
        .catch (error) =>
          $.flashError I18n.t('There was a problem creating the teacher notes column.')
          @setTeacherNotesColumnUpdating(false)
          @renderViewOptionsMenu()

    setTeacherNotesHidden: (hidden) =>
      @setTeacherNotesColumnUpdating(true)
      @renderViewOptionsMenu()
      GradebookApi.updateTeacherNotesColumn(@options.context_id, @options.teacher_notes.id, { hidden })
        .then =>
          @options.teacher_notes.hidden = hidden
          if hidden
            @hideNotesColumn()
          else
            @showNotesColumn()
            @reorderCustomColumns(@customColumns.map (c) -> c.id)
          @setTeacherNotesColumnUpdating(false)
          @renderViewOptionsMenu()
        .catch (error) =>
          if hidden
            $.flashError I18n.t('There was a problem hiding the teacher notes column.')
          else
            $.flashError I18n.t('There was a problem showing the teacher notes column.')
          @setTeacherNotesColumnUpdating(false)
          @renderViewOptionsMenu()
