import { common } from '@kit.AbilityKit'
import { TodoTask, NoteItem, HabitData } from '../model/AppModels'
import { StatBox } from '../components/StatBox'
import { EmptyState } from '../components/EmptyState'
import { PlanDateTimeSelector } from '../components/plan/PlanDateTimeSelector'
import { safeText, getToday, normalizeDateInput, dateToDayNumber, dayNumberToDate, dateInList } from '../utils/DateUtil'
import { PlanStorageService, PlanStorageLoadResult } from '../services/PlanStorageService'
import { AppColors } from '../utils/AppColors'

interface PlanDisplayItem {
  id: number
  planType: string
  title: string
  date: string
  startTime: string
  endTime: string
  summary: string
  statusText: string
  done: boolean
  createDate: string
}
//333
@Component
export struct PlanPage {
  @Prop themeColor: string = AppColors.BLUE

  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext

  @State showAddPanel: boolean = false
  @State createPlanType: string = 'Task'
  @State filterPlanType: string = 'All'
  @State planSearchText: string = ''

  @State planTitle: string = ''
  @State planDate: string = ''
  @State planStartTime: string = ''
  @State planEndTime: string = ''
  @State showConflictConfirm: boolean = false
  @State conflictTitle: string = ''
  @State conflictDetail: string = ''

  @State taskPriority: string = '中'

  @State noteContent: string = ''
  @State noteCategory: string = ''

  @State checkTarget: string = ''
  @State checkTargetDaysText: string = ''

  @State taskNextId: number = 4
  @State noteNextId: number = 3
  @State checkNextId: number = 4

  @State tasks: TodoTask[] = [
    {
      id: 1,
      title: '完成首页框架',
      priority: '高',
      date: '2026-05-17',
      startTime: '09:00',
      endTime: '10:00',
      done: true,
      createDate: '2026-05-17'
    },
    {
      id: 2,
      title: '开发日历安排页',
      priority: '高',
      date: '2026-05-17',
      startTime: '10:30',
      endTime: '12:00',
      done: false,
      createDate: '2026-05-17'
    },
    {
      id: 3,
      title: '实现计划页时间字段',
      priority: '中',
      date: '2026-05-18',
      startTime: '14:00',
      endTime: '15:00',
      done: false,
      createDate: '2026-05-17'
    }
  ]

  @State notes: NoteItem[] = [
    {
      id: 1,
      title: '课程重点',
      content: 'ArkTS、Stage 模型、UIAbility、页面路由、Preferences 本地存储。',
      category: '学习',
      date: '2026-05-17',
      startTime: '16:00',
      endTime: '16:30',
      createDate: '2026-05-17'
    },
    {
      id: 2,
      title: 'App 亮点',
      content: '日历汇总、模块联动、主题切换、本地保存。',
      category: '项目',
      date: '2026-05-18',
      startTime: '19:00',
      endTime: '19:30',
      createDate: '2026-05-17'
    }
  ]

  @State checks: HabitData[] = [
    {
      id: 1,
      title: '学习 ArkTS',
      target: '每天学习 30 分钟',
      days: 3,
      targetDays: 30,
      date: '2026-05-17',
      startTime: '20:00',
      endTime: '20:30',
      checkedDate: '',
      checkedDates: [],
      createDate: '2026-05-17'
    },
    {
      id: 2,
      title: '完成项目开发',
      target: '每天推进一个功能模块',
      days: 2,
      targetDays: 14,
      date: '2026-05-17',
      startTime: '21:00',
      endTime: '22:00',
      checkedDate: '',
      checkedDates: [],
      createDate: '2026-05-17'
    },
    {
      id: 3,
      title: '复盘总结',
      target: '每天记录开发问题和收获',
      days: 1,
      targetDays: 7,
      date: '2026-05-18',
      startTime: '22:30',
      endTime: '23:00',
      checkedDate: '',
      checkedDates: [],
      createDate: '2026-05-17'
    }
  ]

  aboutToAppear(): void {
    if (this.planDate.trim().length === 0) {
      this.planDate = getToday()
    }

    this.initPreferencesAndLoad().then(() => {
      console.info('计划页数据加载完成')
    }).catch(() => {
      console.error('计划页数据加载失败')
    })
  }

  build() {
    Stack() {
      Scroll() {
      Column() {
        Text('计划')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.GRAY_800)
          .margin({ top: 30, bottom: 8 })

        TextInput({ text: this.planSearchText, placeholder: '搜索计划标题、内容、分类、目标或时间...' })
          .width('100%')
          .height(44)
          .backgroundColor(AppColors.WHITE)
          .borderRadius(14)
          .padding({ left: 14, right: 14 })
          .margin({ bottom: 16 })
          .onChange((value: string) => {
            this.planSearchText = value
          })

        this.FilterBar()

        Column() {
          Text('计划概览')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ bottom: 14 })

          Row() {
            StatBox({ themeColor: this.themeColor, title: '全部', value: this.getPlanTotalCount().toString() })
            StatBox({ themeColor: this.themeColor, title: '待办', value: this.tasks.length.toString() })
            StatBox({ themeColor: this.themeColor, title: '便签', value: this.notes.length.toString() })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ bottom: 10 })

          Row() {
            StatBox({ themeColor: this.themeColor, title: '打卡', value: this.checks.length.toString() })
            StatBox({ themeColor: this.themeColor, title: '已完成', value: this.getDoneCount().toString() })
            StatBox({ themeColor: this.themeColor, title: '今日打卡', value: this.getTodayCheckedCount().toString() })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('100%')
        .padding(18)
        .backgroundColor(AppColors.WHITE)
        .borderRadius(18)
        .margin({ bottom: 18 })

        Button(this.showAddPanel ? '取消' : '+ 新增计划')
          .width('100%')
          .height(48)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(this.themeColor)
          .borderRadius(16)
          .margin({ bottom: 14 })
          .onClick(() => {
            this.showAddPanel = !this.showAddPanel

            if (this.showAddPanel && this.planDate.trim().length === 0) {
              this.planDate = getToday()
            }
          })

        if (this.showAddPanel) {
          this.CreatePlanPanel()
        }

        Column() {
          Text('计划列表')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ bottom: 12 })

          if (this.getFilteredPlanItems().length === 0) {
            EmptyState({
              themeColor: this.themeColor,
              iconText: '计',
              title: '暂无匹配计划',
              description: '可以点击“新增计划”创建待办、便签或打卡安排。'
            })
          } else {
            ForEach(this.getFilteredPlanItems(), (item: PlanDisplayItem) => {
              this.PlanItemCard(item)
            }, (item: PlanDisplayItem) => item.planType + '_' + item.id.toString() + '_' + item.done.toString() + '_' + item.date + '_' + item.startTime)
          }
        }
        .width('100%')
        .padding(18)
        .backgroundColor(AppColors.WHITE)
        .borderRadius(18)
        .margin({ bottom: 30 })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.GRAY_BLUE_50)

      if (this.showConflictConfirm) {
        Column() {
          Blank()

          this.ConflictConfirmPanel()

          Blank()
        }
        .width('100%')
        .height('100%')
        .padding({ left: 24, right: 24 })
        .backgroundColor('#66000000')
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ConflictConfirmPanel() {
    Column() {
      Text(this.conflictTitle)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.RED)
        .margin({ bottom: 8 })

      Text(this.conflictDetail)
        .fontSize(14)
        .fontColor(AppColors.GRAY_500)
        .lineHeight(22)
        .margin({ bottom: 14 })

      Text('你可以返回修改时间，也可以仍然保存。')
        .fontSize(13)
        .fontColor(AppColors.GRAY_500)
        .margin({ bottom: 14 })

      Row() {
        Button('返回修改')
          .layoutWeight(1)
          .height(40)
          .fontSize(15)
          .backgroundColor(AppColors.GRAY_400)
          .borderRadius(12)
          .margin({ right: 8 })
          .onClick(() => {
            this.showConflictConfirm = false
          })

        Button('仍然保存')
          .layoutWeight(1)
          .height(40)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(AppColors.RED)
          .borderRadius(12)
          .margin({ left: 8 })
          .onClick(() => {
            this.showConflictConfirm = false
            this.addPlanDirectly()
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor(AppColors.WHITE)
    .borderRadius(20)
    .shadow({ radius: 20, color: '#33000000', offsetX: 0, offsetY: 8 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  FilterBar() {
    Row() {
      ForEach(this.getFilterOptions(), (item: string) => {
        Text(this.getPlanTypeTitle(item))
          .layoutWeight(1)
          .height(36)
          .fontSize(14)
          .fontWeight(this.filterPlanType === item ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.filterPlanType === item ? AppColors.WHITE : AppColors.GRAY_900)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.filterPlanType === item ? this.themeColor : AppColors.WHITE)
          .borderRadius(12)
          .onClick(() => {
            this.filterPlanType = item
          })
      }, (item: string) => item)
    }
    .width('100%')
    .margin({ bottom: 18 })
  }

  @Builder
  CreatePlanPanel() {
    Column() {
      Text('新增计划')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.GRAY_900)
        .margin({ bottom: 12 })

      Text('请选择计划类型')
        .fontSize(13)
        .fontColor(AppColors.GRAY_500)
        .margin({ bottom: 8 })

      Row() {
        this.CreateTypeButton('Task')
        this.CreateTypeButton('Note')
        this.CreateTypeButton('Check')
      }
      .width('100%')
      .margin({ bottom: 14 })

      TextInput({ text: this.planTitle, placeholder: this.getTitlePlaceholder() })
        .width('100%')
        .height(44)
        .backgroundColor(AppColors.GRAY_50)
        .borderRadius(12)
        .padding({ left: 12, right: 12 })
        .margin({ bottom: 10 })
        .onChange((value: string) => {
          this.planTitle = value
        })

      if (this.createPlanType === 'Task') {
        this.TaskPrioritySelector()
      }

      if (this.createPlanType === 'Note') {
        TextInput({ text: this.noteContent, placeholder: '请输入便签内容' })
          .width('100%')
          .height(90)
          .backgroundColor(AppColors.GRAY_50)
          .borderRadius(12)
          .padding({ left: 12, right: 12 })
          .margin({ bottom: 10 })
          .onChange((value: string) => {
            this.noteContent = value
          })

        TextInput({ text: this.noteCategory, placeholder: '请输入分类，例如：学习 / 项目 / 生活' })
          .width('100%')
          .height(44)
          .backgroundColor(AppColors.GRAY_50)
          .borderRadius(12)
          .padding({ left: 12, right: 12 })
          .margin({ bottom: 10 })
          .onChange((value: string) => {
            this.noteCategory = value
          })
      }

      if (this.createPlanType === 'Check') {
        TextInput({ text: this.checkTarget, placeholder: '请输入打卡目标，例如：每天学习 30 分钟' })
          .width('100%')
          .height(44)
          .backgroundColor(AppColors.GRAY_50)
          .borderRadius(12)
          .padding({ left: 12, right: 12 })
          .margin({ bottom: 10 })
          .onChange((value: string) => {
            this.checkTarget = value
          })

        TextInput({ text: this.checkTargetDaysText, placeholder: '请输入计划打卡天数，例如：30' })
          .width('100%')
          .height(44)
          .backgroundColor(AppColors.GRAY_50)
          .borderRadius(12)
          .padding({ left: 12, right: 12 })
          .margin({ bottom: 10 })
          .onChange((value: string) => {
            this.checkTargetDaysText = value
          })
      }

      PlanDateTimeSelector({
        themeColor: this.themeColor,
        planDate: this.planDate,
        planStartTime: this.planStartTime,
        planEndTime: this.planEndTime,
        onDateChange: (dateText: string) => {
          this.planDate = dateText
        },
        onStartTimeChange: (timeText: string) => {
          this.planStartTime = timeText
        },
        onEndTimeChange: (timeText: string) => {
          this.planEndTime = timeText
        }
      })

      Button('保存' + this.getPlanTypeTitle(this.createPlanType))
        .width('100%')
        .height(44)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .backgroundColor(AppColors.GREEN)
        .borderRadius(12)
        .onClick(() => {
          this.addPlan()
        })
    }
    .width('100%')
    .padding(18)
    .backgroundColor(AppColors.WHITE)
    .borderRadius(18)
    .margin({ bottom: 18 })
  }

  @Builder
  CreateTypeButton(type: string) {
    Text(this.getPlanTypeTitle(type))
      .layoutWeight(1)
      .height(38)
      .fontSize(14)
      .fontWeight(this.createPlanType === type ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.createPlanType === type ? AppColors.WHITE : AppColors.GRAY_900)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.createPlanType === type ? this.themeColor : AppColors.GRAY_50)
      .borderRadius(12)
      .margin({ right: type === 'Check' ? 0 : 8 })
      .onClick(() => {
        this.createPlanType = type
      })
  }

  @Builder
  TaskPrioritySelector() {
    Column() {
      Text('请选择优先级')
        .fontSize(13)
        .fontColor(AppColors.GRAY_500)
        .margin({ bottom: 8 })

      Row() {
        this.PriorityButton('高')
        this.PriorityButton('中')
        this.PriorityButton('低')
      }
      .width('100%')
    }
    .width('100%')
    .margin({ bottom: 10 })
  }

  @Builder
  PriorityButton(priority: string) {
    Text(priority)
      .layoutWeight(1)
      .height(38)
      .fontSize(14)
      .fontWeight(this.taskPriority === priority ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.taskPriority === priority ? AppColors.WHITE : this.getPriorityColor(priority))
      .textAlign(TextAlign.Center)
      .backgroundColor(this.taskPriority === priority ? this.getPriorityColor(priority) : AppColors.GRAY_50)
      .borderRadius(12)
      .margin({ right: priority === '低' ? 0 : 8 })
      .onClick(() => {
        this.taskPriority = priority
      })
  }

  @Builder
  PlanItemCard(item: PlanDisplayItem) {
    Column() {
      Row() {
        Text(this.getPlanTypeTag(item.planType))
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getPlanTypeColor(item.planType))
          .backgroundColor(this.getPlanTypeBgColor(item.planType))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(8)
          .margin({ right: 8 })

        Text(item.title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(item.done ? AppColors.GRAY_400 : AppColors.GRAY_900)
          .layoutWeight(1)

        if (item.planType !== 'Note') {
          Text(item.statusText)
            .fontSize(12)
            .fontColor(item.done ? AppColors.GREEN : AppColors.RED)
            .backgroundColor(item.done ? AppColors.GREEN_100 : AppColors.RED_100)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(8)
        }
      }
      .width('100%')
      .margin({ bottom: 8 })

      Text(item.summary)
        .fontSize(14)
        .fontColor(AppColors.GRAY_500)
        .margin({ bottom: 8 })

      Text('日期：' + safeText(item.date, '未设置') + '    时间：' + safeText(item.startTime, '未设置') + ' - ' + safeText(item.endTime, '未设置'))
        .fontSize(13)
        .fontColor(this.themeColor)
        .margin({ bottom: 12 })

      if (item.planType === 'Check') {
        Column() {
          Row() {
            Text('进度：' + this.getCheckProgressTextById(item.id))
              .fontSize(12)
              .fontColor(AppColors.GRAY_500)
              .layoutWeight(1)

            Text(this.isCheckCheckedTodayById(item.id) ? '今日已打卡' : '今日未打卡')
              .fontSize(12)
              .fontColor(this.isCheckCheckedTodayById(item.id) ? AppColors.GREEN : AppColors.RED)
          }
          .width('100%')
          .margin({ bottom: 6 })

          Row() {
            Row() {}
            .width(this.getCheckProgressWidthById(item.id))
            .height(6)
            .backgroundColor(AppColors.GREEN)
            .borderRadius(3)
          }
          .width('100%')
          .height(6)
          .backgroundColor(AppColors.GRAY_200)
          .borderRadius(3)
        }
        .width('100%')
        .padding(10)
        .backgroundColor(AppColors.GREEN_50)
        .borderRadius(10)
        .margin({ bottom: 12 })
      }

      Row() {
        if (item.planType === 'Task') {
          Button(item.done ? '恢复' : '完成')
            .layoutWeight(1)
            .height(38)
            .fontSize(14)
            .backgroundColor(item.done ? AppColors.GRAY_400 : AppColors.GREEN)
            .borderRadius(12)
            .margin({ right: 8 })
            .onClick(() => {
              this.toggleTask(item.id)
            })
        }

        if (item.planType === 'Check') {
          Button(this.isCheckCheckedTodayById(item.id) ? '取消打卡' : '今日打卡')
            .layoutWeight(1)
            .height(38)
            .fontSize(14)
            .backgroundColor(this.isCheckCheckedTodayById(item.id) ? AppColors.GRAY_400 : AppColors.GREEN)
            .borderRadius(12)
            .margin({ right: 8 })
            .onClick(() => {
              this.toggleCheck(item.id)
            })
        }

        Button('删除')
          .layoutWeight(1)
          .height(38)
          .fontSize(14)
          .backgroundColor(AppColors.RED)
          .borderRadius(12)
          .margin({ left: item.planType === 'Note' ? 0 : 8 })
          .onClick(() => {
            this.deletePlanItem(item.planType, item.id)
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(item.done ? AppColors.GREEN_50 : AppColors.GRAY_50)
    .borderRadius(12)
    .margin({ bottom: 10 })
    .alignItems(HorizontalAlign.Start)
  }

  async initPreferencesAndLoad(): Promise<void> {
    await this.loadAllPlanData()
  }

  async loadAllPlanData(): Promise<void> {
    let result: PlanStorageLoadResult = await PlanStorageService.loadAllPlanData(
      this.context,
      this.tasks,
      this.taskNextId,
      this.notes,
      this.noteNextId,
      this.checks,
      this.checkNextId
    )

    this.tasks = result.tasks
    this.taskNextId = result.taskNextId
    this.notes = result.notes
    this.noteNextId = result.noteNextId
    this.checks = result.checks
    this.checkNextId = result.checkNextId
  }

  async saveTasks(): Promise<void> {
    await PlanStorageService.saveTasks(this.context, this.tasks, this.taskNextId)
  }

  async saveNotes(): Promise<void> {
    await PlanStorageService.saveNotes(this.context, this.notes, this.noteNextId)
  }

  async saveChecks(): Promise<void> {
    await PlanStorageService.saveChecks(this.context, this.checks, this.checkNextId)
  }

  getFilterOptions(): string[] {
    return ['All', 'Task', 'Note', 'Check']
  }

  getPlanTypeTitle(type: string): string {
    if (type === 'Task') {
      return '待办'
    }
    if (type === 'Note') {
      return '便签'
    }
    if (type === 'Check') {
      return '打卡'
    }
    return '全部'
  }

  getPlanTypeTag(type: string): string {
    if (type === 'Task') {
      return '待办'
    }
    if (type === 'Note') {
      return '便签'
    }
    if (type === 'Check') {
      return '打卡'
    }
    return 'Plan'
  }

  getPlanTypeColor(type: string): string {
    if (type === 'Task') {
      return this.themeColor
    }
    if (type === 'Note') {
      return AppColors.GREEN
    }
    if (type === 'Check') {
      return AppColors.RED
    }
    return AppColors.GRAY_900
  }

  getPlanTypeBgColor(type: string): string {
    if (type === 'Task') {
      return AppColors.INDIGO_50
    }
    if (type === 'Note') {
      return AppColors.GREEN_100
    }
    if (type === 'Check') {
      return AppColors.RED_100
    }
    return AppColors.GRAY_100
  }

  getTitlePlaceholder(): string {
    if (this.createPlanType === 'Task') {
      return '请输入待办名称，例如：完成课程报告'
    }
    if (this.createPlanType === 'Note') {
      return '请输入便签标题'
    }
    return '请输入打卡名称，例如：背单词'
  }

  getPriorityColor(priority: string): string {
    if (priority === '高') {
      return AppColors.RED
    }

    if (priority === '中') {
      return this.themeColor
    }

    return AppColors.GREEN
  }

  getPlanTotalCount(): number {
    return this.tasks.length + this.notes.length + this.checks.length
  }

  getDoneCount(): number {
    return this.tasks.filter((item: TodoTask) => {
      return item.done
    }).length
  }

  getUndoneCount(): number {
    return this.tasks.filter((item: TodoTask) => {
      return !item.done
    }).length
  }

  getTodayCheckedCount(): number {
    return this.checks.filter((item: HabitData) => {
      return this.isCheckCheckedToday(item)
    }).length
  }

  getFilteredPlanItems(): PlanDisplayItem[] {
    let list: PlanDisplayItem[] = []

    this.tasks.forEach((task: TodoTask) => {
      list.push({
        id: task.id,
        planType: 'Task',
        title: task.title,
        date: task.date,
        startTime: task.startTime,
        endTime: task.endTime,
        summary: '优先级：' + safeText(task.priority, '中'),
        statusText: task.done ? '已完成' : '未完成',
        done: task.done,
        createDate: task.createDate
      })
    })

    this.notes.forEach((note: NoteItem) => {
      list.push({
        id: note.id,
        planType: 'Note',
        title: note.title,
        date: note.date,
        startTime: note.startTime,
        endTime: note.endTime,
        summary: '分类：' + safeText(note.category, '默认') + '；内容：' + safeText(note.content, '暂无内容'),
        statusText: '便签',
        done: false,
        createDate: note.createDate
      })
    })

    this.checks.forEach((check: HabitData) => {
      list.push({
        id: check.id,
        planType: 'Check',
        title: check.title,
        date: check.date,
        startTime: check.startTime,
        endTime: check.endTime,
        summary: '目标：' + safeText(check.target, '每日坚持完成') + '；已打卡：' + check.days.toString() + '/' + check.targetDays.toString() + ' 天',
        statusText: this.isCheckCheckedToday(check) ? '已打卡' : '未打卡',
        done: this.isCheckCheckedToday(check),
        createDate: check.createDate
      })
    })

    if (this.filterPlanType !== 'All') {
      list = list.filter((item: PlanDisplayItem) => {
        return item.planType === this.filterPlanType
      })
    }

    if (this.planSearchText.trim().length > 0) {
      let keyword = this.planSearchText.trim().toLowerCase()
      list = list.filter((item: PlanDisplayItem) => {
        return item.title.toLowerCase().includes(keyword)
          || item.summary.toLowerCase().includes(keyword)
          || item.date.toLowerCase().includes(keyword)
          || item.startTime.toLowerCase().includes(keyword)
          || item.endTime.toLowerCase().includes(keyword)
          || item.planType.toLowerCase().includes(keyword)
      })
    }

    list.sort((a: PlanDisplayItem, b: PlanDisplayItem) => {
      if (a.date > b.date) {
        return -1
      }
      if (a.date < b.date) {
        return 1
      }
      if (a.startTime > b.startTime) {
        return -1
      }
      if (a.startTime < b.startTime) {
        return 1
      }
      return 0
    })

    return list
  }

  addPlan(): void {
    if (this.planTitle.trim().length === 0) {
      return
    }

    let conflicts = this.getCurrentPlanConflictTexts()
    if (conflicts.length > 0) {
      this.conflictTitle = '检测到时间冲突'
      this.conflictDetail = conflicts.join('\n')
      this.showConflictConfirm = true
      return
    }

    this.addPlanDirectly()
  }

  addPlanDirectly(): void {
    if (this.createPlanType === 'Task') {
      this.addTask()
    } else if (this.createPlanType === 'Note') {
      this.addNote()
    } else {
      this.addCheck()
    }
  }

  addTask(): void {
    if (this.planTitle.trim().length === 0) {
      return
    }

    let newTask: TodoTask = {
      id: this.taskNextId,
      title: this.planTitle,
      priority: this.taskPriority,
      date: normalizeDateInput(this.planDate),
      startTime: this.planStartTime.trim().length === 0 ? '未设置' : this.planStartTime,
      endTime: this.planEndTime.trim().length === 0 ? '未设置' : this.planEndTime,
      done: false,
      createDate: getToday()
    }

    this.tasks = [newTask, ...this.tasks]
    this.taskNextId = this.taskNextId + 1
    this.resetCreateForm()

    this.saveTasks().then(() => {
      console.info('Task 保存成功')
    }).catch(() => {
      console.error('Task 保存失败')
    })
  }

  addNote(): void {
    if (this.planTitle.trim().length === 0) {
      return
    }

    let newNote: NoteItem = {
      id: this.noteNextId,
      title: this.planTitle,
      content: this.noteContent.trim().length === 0 ? '暂无内容' : this.noteContent,
      category: this.noteCategory.trim().length === 0 ? '默认' : this.noteCategory,
      date: normalizeDateInput(this.planDate),
      startTime: this.planStartTime.trim().length === 0 ? '未设置' : this.planStartTime,
      endTime: this.planEndTime.trim().length === 0 ? '未设置' : this.planEndTime,
      createDate: getToday()
    }

    this.notes = [newNote, ...this.notes]
    this.noteNextId = this.noteNextId + 1
    this.resetCreateForm()

    this.saveNotes().then(() => {
      console.info('Note 保存成功')
    }).catch(() => {
      console.error('Note 保存失败')
    })
  }

  addCheck(): void {
    if (this.planTitle.trim().length === 0) {
      return
    }

    let newCheck: HabitData = {
      id: this.checkNextId,
      title: this.planTitle,
      target: this.checkTarget.trim().length === 0 ? '每日坚持完成' : this.checkTarget,
      days: 0,
      targetDays: this.parseTargetDays(this.checkTargetDaysText),
      date: normalizeDateInput(this.planDate),
      startTime: this.planStartTime.trim().length === 0 ? '未设置' : this.planStartTime,
      endTime: this.planEndTime.trim().length === 0 ? '未设置' : this.planEndTime,
      checkedDate: '',
      checkedDates: [],
      createDate: getToday()
    }

    this.checks = [newCheck, ...this.checks]
    this.checkNextId = this.checkNextId + 1
    this.resetCreateForm()

    this.saveChecks().then(() => {
      console.info('Check 保存成功')
    }).catch(() => {
      console.error('Check 保存失败')
    })
  }

  getCurrentPlanConflictTexts(): string[] {
    let normalizedDate = normalizeDateInput(this.planDate)
    let startTime = this.planStartTime.trim().length === 0 ? '未设置' : this.planStartTime
    let endTime = this.planEndTime.trim().length === 0 ? '未设置' : this.planEndTime

    if (!this.isValidTimeRange(startTime, endTime)) {
      return []
    }

    let result: string[] = []
    let dates = this.getCurrentPlanConflictDates(normalizedDate)

    dates.forEach((dateText: string) => {
      let dayConflicts = this.getConflictTextsByDate(dateText, startTime, endTime)
      dayConflicts.forEach((item: string) => {
        result.push(item)
      })
    })

    return result
  }

  getCurrentPlanConflictDates(startDate: string): string[] {
    let result: string[] = []

    if (this.createPlanType !== 'Check') {
      result.push(startDate)
      return result
    }

    let targetDays = this.parseTargetDays(this.checkTargetDaysText)
    let startIndex = dateToDayNumber(startDate)

    for (let i = 0; i < targetDays; i++) {
      result.push(dayNumberToDate(startIndex + i))
    }

    return result
  }

  getConflictTextsByDate(dateText: string, startTime: string, endTime: string): string[] {
    let result: string[] = []

    this.tasks.forEach((item: TodoTask) => {
      if (item.date === dateText && this.isTimeOverlap(startTime, endTime, item.startTime, item.endTime)) {
        result.push('【' + dateText + '】与待办《' + item.title + '》冲突：' + item.startTime + ' - ' + item.endTime)
      }
    })

    this.notes.forEach((item: NoteItem) => {
      if (item.date === dateText && this.isTimeOverlap(startTime, endTime, item.startTime, item.endTime)) {
        result.push('【' + dateText + '】与便签《' + item.title + '》冲突：' + item.startTime + ' - ' + item.endTime)
      }
    })

    this.checks.forEach((item: HabitData) => {
      let scheduleDates = this.getExistingCheckScheduleDates(item)
      if (dateInList(dateText, scheduleDates) && this.isTimeOverlap(startTime, endTime, item.startTime, item.endTime)) {
        result.push('【' + dateText + '】与打卡《' + item.title + '》冲突：' + item.startTime + ' - ' + item.endTime)
      }
    })

    return result
  }

  getExistingCheckScheduleDates(check: HabitData): string[] {
    let result: string[] = []
    let startDate = normalizeDateInput(check.date)
    let checkedDates = this.getCheckCheckedDates(check)
    let targetDays = check.targetDays

    if (targetDays <= 0) {
      targetDays = 30
    }

    let startIndex = dateToDayNumber(startDate)
    let todayIndex = dateToDayNumber(getToday())

    let checkedBeforeToday = 0
    checkedDates.forEach((dateText: string) => {
      let dateIndex = dateToDayNumber(dateText)
      if (dateIndex >= startIndex && dateIndex < todayIndex) {
        checkedBeforeToday = checkedBeforeToday + 1
      }
    })

    let elapsedBeforeToday = todayIndex - startIndex
    if (elapsedBeforeToday < 0) {
      elapsedBeforeToday = 0
    }

    let missedBeforeToday = elapsedBeforeToday - checkedBeforeToday
    if (missedBeforeToday < 0) {
      missedBeforeToday = 0
    }

    let endIndex = startIndex + targetDays + missedBeforeToday - 1

    if (checkedDates.length >= targetDays) {
      let lastCheckedIndex = startIndex
      checkedDates.forEach((dateText: string) => {
        let dateIndex = dateToDayNumber(dateText)
        if (dateIndex > lastCheckedIndex) {
          lastCheckedIndex = dateIndex
        }
      })
      endIndex = lastCheckedIndex
    }

    for (let i = startIndex; i <= endIndex; i++) {
      result.push(dayNumberToDate(i))
    }

    return result
  }

  getCheckCheckedDates(check: HabitData): string[] {
    let result: string[] = []

    if (check.checkedDates !== undefined && check.checkedDates !== null) {
      check.checkedDates.forEach((dateText: string) => {
        let normalizedDate = normalizeDateInput(dateText)
        if (!dateInList(normalizedDate, result)) {
          result.push(normalizedDate)
        }
      })
    }

    if (check.checkedDate !== undefined && check.checkedDate !== null && check.checkedDate.length > 0) {
      let normalizedDate = normalizeDateInput(check.checkedDate)
      if (!dateInList(normalizedDate, result)) {
        result.push(normalizedDate)
      }
    }

    return result
  }

  isValidTimeRange(startTime: string, endTime: string): boolean {
    let start = this.timeToMinutes(startTime)
    let end = this.timeToMinutes(endTime)
    return start >= 0 && end >= 0 && end > start
  }

  isTimeOverlap(startA: string, endA: string, startB: string, endB: string): boolean {
    let aStart = this.timeToMinutes(startA)
    let aEnd = this.timeToMinutes(endA)
    let bStart = this.timeToMinutes(startB)
    let bEnd = this.timeToMinutes(endB)

    if (aStart < 0 || aEnd < 0 || bStart < 0 || bEnd < 0) {
      return false
    }

    if (aEnd <= aStart || bEnd <= bStart) {
      return false
    }

    return aStart < bEnd && bStart < aEnd
  }

  timeToMinutes(timeText: string): number {
    let raw = safeText(timeText, '').trim()
    if (raw.length === 0 || raw === '未设置') {
      return -1
    }

    raw = raw.replace('：', ':')

    let parts = raw.split(':')
    if (parts.length !== 2) {
      return -1
    }

    let hour = Number(parts[0])
    let minute = Number(parts[1])

    if (isNaN(hour) || isNaN(minute)) {
      return -1
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return -1
    }

    return Math.floor(hour) * 60 + Math.floor(minute)
  }

  resetCreateForm(): void {
    this.planTitle = ''
    this.planDate = getToday()
    this.planStartTime = ''
    this.planEndTime = ''

    this.taskPriority = '中'

    this.noteContent = ''
    this.noteCategory = ''

    this.checkTarget = ''
    this.checkTargetDaysText = ''

    this.showAddPanel = false
    this.showConflictConfirm = false
    this.conflictTitle = ''
    this.conflictDetail = ''
  }

  parseTargetDays(value: string): number {
    let parsed = Number(value)
    if (isNaN(parsed) || parsed <= 0) {
      return 30
    }

    return Math.floor(parsed)
  }

  toggleTask(id: number): void {
    let newTasks: TodoTask[] = []

    this.tasks.forEach((item: TodoTask) => {
      newTasks.push({
        id: item.id,
        title: item.title,
        priority: item.priority,
        date: item.date,
        startTime: item.startTime,
        endTime: item.endTime,
        done: item.id === id ? !item.done : item.done,
        createDate: item.createDate
      })
    })

    this.tasks = newTasks

    this.saveTasks().then(() => {
      console.info('Task 状态已保存')
    }).catch(() => {
      console.error('Task 状态保存失败')
    })
  }

  toggleCheck(id: number): void {
    let today = getToday()
    let newChecks: HabitData[] = []

    this.checks.forEach((item: HabitData) => {
      let checkedList: string[] = []

      if (item.checkedDates !== undefined && item.checkedDates !== null) {
        item.checkedDates.forEach((dateText: string) => {
          if (checkedList.indexOf(dateText) < 0) {
            checkedList.push(dateText)
          }
        })
      }

      if (item.id === id) {
        let alreadyChecked = checkedList.indexOf(today) >= 0

        if (alreadyChecked) {
          checkedList = checkedList.filter((dateText: string) => {
            return dateText !== today
          })
        } else {
          checkedList.push(today)
        }

        newChecks.push({
          id: item.id,
          title: item.title,
          target: item.target,
          days: checkedList.length,
          targetDays: item.targetDays,
          date: item.date,
          startTime: item.startTime,
          endTime: item.endTime,
          checkedDate: alreadyChecked ? '' : today,
          checkedDates: checkedList,
          createDate: item.createDate
        })
      } else {
        newChecks.push({
          id: item.id,
          title: item.title,
          target: item.target,
          days: item.days,
          targetDays: item.targetDays,
          date: item.date,
          startTime: item.startTime,
          endTime: item.endTime,
          checkedDate: item.checkedDate,
          checkedDates: checkedList,
          createDate: item.createDate
        })
      }
    })

    this.checks = newChecks

    this.saveChecks().then(() => {
      console.info('Check 打卡状态已保存')
    }).catch(() => {
      console.error('Check 打卡状态保存失败')
    })
  }

  deletePlanItem(planType: string, id: number): void {
    if (planType === 'Task') {
      this.deleteTask(id)
    } else if (planType === 'Note') {
      this.deleteNote(id)
    } else if (planType === 'Check') {
      this.deleteCheck(id)
    }
  }

  deleteTask(id: number): void {
    this.tasks = this.tasks.filter((item: TodoTask) => {
      return item.id !== id
    })

    this.saveTasks().then(() => {
      console.info('Task 删除后已保存')
    }).catch(() => {
      console.error('Task 删除后保存失败')
    })
  }

  deleteNote(id: number): void {
    this.notes = this.notes.filter((item: NoteItem) => {
      return item.id !== id
    })

    this.saveNotes().then(() => {
      console.info('Note 删除后已保存')
    }).catch(() => {
      console.error('Note 删除后保存失败')
    })
  }

  deleteCheck(id: number): void {
    this.checks = this.checks.filter((item: HabitData) => {
      return item.id !== id
    })

    this.saveChecks().then(() => {
      console.info('Check 删除后已保存')
    }).catch(() => {
      console.error('Check 删除后保存失败')
    })
  }

  isCheckCheckedToday(check: HabitData): boolean {
    if (check.checkedDates !== undefined && check.checkedDates !== null) {
      return check.checkedDates.indexOf(getToday()) >= 0
    }
    return check.checkedDate === getToday()
  }

  isCheckCheckedTodayById(id: number): boolean {
    let result = false

    this.checks.forEach((item: HabitData) => {
      if (item.id === id && this.isCheckCheckedToday(item)) {
        result = true
      }
    })

    return result
  }

  getCheckProgressValue(check: HabitData): number {
    if (check.targetDays <= 0) {
      return 0
    }

    let value = Math.round(check.days * 100 / check.targetDays)
    if (value > 100) {
      return 100
    }

    if (value < 0) {
      return 0
    }

    return value
  }

  getCheckProgressValueById(id: number): number {
    let result = 0

    this.checks.forEach((item: HabitData) => {
      if (item.id === id) {
        result = this.getCheckProgressValue(item)
      }
    })

    return result
  }

  getCheckProgressTextById(id: number): string {
    return this.getCheckProgressValueById(id).toString() + '%'
  }

  getCheckProgressWidthById(id: number): string {
    return this.getCheckProgressValueById(id).toString() + '%'
  }


}