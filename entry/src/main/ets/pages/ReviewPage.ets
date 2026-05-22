import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { TodoTask, NoteItem, HabitData, FocusRecord } from '../model/AppModels'
import { StatBox } from '../components/StatBox'
import { getToday, dateToDayNumber, safeText, normalizeDateInput } from '../utils/DateUtil'
import {
  TASKS_KEY as PLAN_TASKS_KEY,
  NOTES_KEY as PLAN_NOTES_KEY,
  HABITS_KEY as PLAN_HABITS_KEY,
  FOCUS_RECORDS_KEY as PLAN_FOCUS_RECORDS_KEY
} from '../utils/StoreConstants'
import { getTimePlanPreferences } from '../utils/PreferenceUtil'
import { AppColors } from '../utils/AppColors'

@Component
export struct ReviewPage {
  @Prop themeColor: string = AppColors.BLUE

  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
  dataPreferences: preferences.Preferences | null = null

  readonly TASKS_KEY: string = PLAN_TASKS_KEY
  readonly NOTES_KEY: string = PLAN_NOTES_KEY
  readonly HABITS_KEY: string = PLAN_HABITS_KEY
  readonly FOCUS_RECORDS_KEY: string = PLAN_FOCUS_RECORDS_KEY

  @State tasks: TodoTask[] = []
  @State notes: NoteItem[] = []
  @State checks: HabitData[] = []
  @State focusRecords: FocusRecord[] = []
  @State syncTip: string = '统计数据会自动同步'

  refreshTimerId: number = -1

  aboutToAppear(): void {
    this.initPreferencesAndLoad().then(() => {
      this.startAutoRefresh()
      console.info('统计页数据加载完成')
    }).catch(() => {
      this.syncTip = '统计页数据加载失败'
      console.error('统计页数据加载失败')
    })
  }

  aboutToDisappear(): void {
    this.stopAutoRefresh()
  }

  build() {
    Scroll() {
      Column() {
        Text('统计')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.GRAY_800)
          .margin({ top: 30, bottom: 8 })

        Text('查看计划完成、打卡坚持和专注情况')
          .fontSize(15)
          .fontColor(AppColors.GRAY_500)
          .margin({ bottom: 8 })

        Text(this.syncTip)
          .fontSize(13)
          .fontColor(this.themeColor)
          .margin({ bottom: 20 })

        Column() {
          Text('今日概览')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ bottom: 14 })

          Row() {
            StatBox({ themeColor: this.themeColor, title: '待办', value: this.tasks.length.toString() })
            StatBox({ themeColor: this.themeColor, title: '已完成', value: this.getDoneTaskCount().toString() })
            StatBox({ themeColor: this.themeColor, title: '今日打卡', value: this.getTodayCheckedCount().toString() })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ bottom: 10 })

          Row() {
            StatBox({ themeColor: this.themeColor, title: '便签', value: this.notes.length.toString() })
            StatBox({ themeColor: this.themeColor, title: '专注次数', value: this.getTodayFocusCount().toString() })
            StatBox({ themeColor: this.themeColor, title: '专注分钟', value: this.getTodayFocusMinutes().toString() })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('100%')
        .padding(18)
        .backgroundColor(AppColors.WHITE)
        .borderRadius(18)
        .margin({ bottom: 18 })

        Column() {
          Text('计划完成率')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ bottom: 12 })

          Text(this.getTaskRateText())
            .fontSize(42)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeColor)
            .margin({ bottom: 12 })

          Row() {
            Row() {}
            .width(this.getTaskRateText())
            .height(8)
            .backgroundColor(this.themeColor)
            .borderRadius(4)
          }
          .width('100%')
          .height(8)
          .backgroundColor(AppColors.GRAY_200)
          .borderRadius(4)

          Text('未完成待办：' + this.getUndoneTaskCount().toString() + ' 个')
            .fontSize(14)
            .fontColor(AppColors.GRAY_500)
            .width('100%')
            .margin({ top: 12 })
        }
        .width('100%')
        .padding(18)
        .backgroundColor(AppColors.WHITE)
        .borderRadius(18)
        .margin({ bottom: 18 })

        Column() {
          Text('本周专注')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ bottom: 14 })

          Row() {
            StatBox({ themeColor: this.themeColor, title: '本周次数', value: this.getWeekFocusCount().toString() })
            StatBox({ themeColor: this.themeColor, title: '本周分钟', value: this.getWeekFocusMinutes().toString() })
            StatBox({ themeColor: this.themeColor, title: '累计分钟', value: this.getTotalFocusMinutes().toString() })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('100%')
        .padding(18)
        .backgroundColor(AppColors.WHITE)
        .borderRadius(18)
        .margin({ bottom: 18 })

        Column() {
          Text('打卡统计')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ bottom: 14 })

          if (this.checks.length === 0) {
            Text('暂无打卡计划')
              .fontSize(15)
              .fontColor(AppColors.GRAY_400)
              .width('100%')
              .padding(12)
          } else {
            ForEach(this.checks, (check: HabitData) => {
              this.CheckReviewItem(check)
            }, (check: HabitData) => check.id.toString() + '_' + check.days.toString() + '_' + check.checkedDates.length.toString() + '_' + this.isCheckCheckedToday(check).toString())
          }
        }
        .width('100%')
        .padding(18)
        .backgroundColor(AppColors.WHITE)
        .borderRadius(18)
        .margin({ bottom: 18 })

        Column() {
          Text('复盘建议')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ bottom: 12 })

          Text(this.getReviewSuggestion())
            .fontSize(15)
            .fontColor(AppColors.GRAY_900)
            .lineHeight(24)
            .width('100%')
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
  }

  @Builder
  CheckReviewItem(check: HabitData) {
    Column() {
      Row() {
        Text(check.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.GRAY_900)
          .layoutWeight(1)

        Text(this.isCheckCheckedToday(check) ? '今日已打卡' : '今日未打卡')
          .fontSize(12)
          .fontColor(this.isCheckCheckedToday(check) ? AppColors.GREEN : AppColors.RED)
          .backgroundColor(this.isCheckCheckedToday(check) ? AppColors.GREEN_100 : AppColors.RED_100)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(8)
      }
      .width('100%')
      .margin({ bottom: 8 })

      Text('目标：' + safeText(check.target, '每日坚持完成'))
        .fontSize(13)
        .fontColor(AppColors.GRAY_500)
        .margin({ bottom: 8 })

      Row() {
        Row() {}
        .width(this.getCheckProgressWidth(check))
        .height(6)
        .backgroundColor(AppColors.GREEN)
        .borderRadius(3)
      }
      .width('100%')
      .height(6)
      .backgroundColor(AppColors.GRAY_200)
      .borderRadius(3)
      .margin({ bottom: 6 })

      Text('进度：' + check.days.toString() + '/' + check.targetDays.toString() + ' 天，完成率 ' + this.getCheckProgressText(check))
        .fontSize(12)
        .fontColor(AppColors.GRAY_500)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(AppColors.GRAY_50)
    .borderRadius(12)
    .margin({ bottom: 10 })
  }

  async initPreferencesAndLoad(): Promise<void> {
    await this.initPreferences()
    await this.loadAllData()
  }

  async initPreferences(): Promise<void> {
    if (this.dataPreferences !== null) {
      return
    }

    this.dataPreferences = await getTimePlanPreferences(this.context)
  }

  startAutoRefresh(): void {
    if (this.refreshTimerId !== -1) {
      return
    }

    this.refreshTimerId = setInterval(() => {
      this.loadAllData().then(() => {
        this.syncTip = '统计数据已自动同步'
      }).catch(() => {
        this.syncTip = '统计数据同步失败'
      })
    }, 800)
  }

  stopAutoRefresh(): void {
    if (this.refreshTimerId !== -1) {
      clearInterval(this.refreshTimerId)
      this.refreshTimerId = -1
    }
  }

  async loadAllData(): Promise<void> {
    // 每次都重新获取 Preferences，避免统计页读取到旧缓存。
    this.dataPreferences = await getTimePlanPreferences(this.context)

    if (this.dataPreferences === null) {
      return
    }

    let loadedTasks: TodoTask[] = []
    let loadedNotes: NoteItem[] = []
    let loadedChecks: HabitData[] = []
    let loadedFocusRecords: FocusRecord[] = []

    let tasksValue = await this.dataPreferences.get(this.TASKS_KEY, '')
    if (typeof tasksValue === 'string' && tasksValue.length > 0) {
      try {
        loadedTasks = this.normalizeTasks(JSON.parse(tasksValue) as TodoTask[])
      } catch (err) {
        console.error('统计页读取待办失败')
      }
    }

    let notesValue = await this.dataPreferences.get(this.NOTES_KEY, '')
    if (typeof notesValue === 'string' && notesValue.length > 0) {
      try {
        loadedNotes = this.normalizeNotes(JSON.parse(notesValue) as NoteItem[])
      } catch (err) {
        console.error('统计页读取便签失败')
      }
    }

    let checksValue = await this.dataPreferences.get(this.HABITS_KEY, '')
    if (typeof checksValue === 'string' && checksValue.length > 0) {
      try {
        loadedChecks = this.normalizeChecks(JSON.parse(checksValue) as HabitData[])
      } catch (err) {
        console.error('统计页读取打卡失败')
      }
    }

    let recordsValue = await this.dataPreferences.get(this.FOCUS_RECORDS_KEY, '')
    if (typeof recordsValue === 'string' && recordsValue.length > 0) {
      try {
        loadedFocusRecords = this.normalizeFocusRecords(JSON.parse(recordsValue) as FocusRecord[])
      } catch (err) {
        console.error('统计页读取专注记录失败')
      }
    }

    this.tasks = loadedTasks
    this.notes = loadedNotes
    this.checks = loadedChecks
    this.focusRecords = loadedFocusRecords
  }

  normalizeTasks(list: TodoTask[]): TodoTask[] {
    let result: TodoTask[] = []

    list.forEach((item: TodoTask) => {
      result.push({
        id: item.id,
        title: safeText(item.title, '未命名待办'),
        priority: safeText(item.priority, '中'),
        date: normalizeDateInput(safeText(item.date, getToday())),
        startTime: safeText(item.startTime, '未设置'),
        endTime: safeText(item.endTime, '未设置'),
        done: item.done === true,
        createDate: normalizeDateInput(safeText(item.createDate, getToday()))
      })
    })

    return result
  }

  normalizeNotes(list: NoteItem[]): NoteItem[] {
    let result: NoteItem[] = []

    list.forEach((item: NoteItem) => {
      result.push({
        id: item.id,
        title: safeText(item.title, '未命名便签'),
        content: safeText(item.content, '暂无内容'),
        category: safeText(item.category, '默认'),
        date: normalizeDateInput(safeText(item.date, getToday())),
        startTime: safeText(item.startTime, '未设置'),
        endTime: safeText(item.endTime, '未设置'),
        createDate: normalizeDateInput(safeText(item.createDate, safeText(item.date, getToday())))
      })
    })

    return result
  }

  normalizeChecks(list: HabitData[]): HabitData[] {
    let result: HabitData[] = []

    list.forEach((item: HabitData) => {
      let finalCheckedDates: string[] = []

      if (item.checkedDates !== undefined && item.checkedDates !== null) {
        item.checkedDates.forEach((dateText: string) => {
          let normalizedDate = normalizeDateInput(dateText)
          if (finalCheckedDates.indexOf(normalizedDate) < 0) {
            finalCheckedDates.push(normalizedDate)
          }
        })
      }

      if (item.checkedDate !== undefined && item.checkedDate !== null && item.checkedDate.length > 0) {
        let normalizedDate = normalizeDateInput(item.checkedDate)
        if (finalCheckedDates.indexOf(normalizedDate) < 0) {
          finalCheckedDates.push(normalizedDate)
        }
      }

      let finalTargetDays = 30
      if (typeof item.targetDays === 'number' && item.targetDays > 0) {
        finalTargetDays = item.targetDays
      }

      let finalDays = item.days
      if (finalCheckedDates.length > finalDays) {
        finalDays = finalCheckedDates.length
      }

      result.push({
        id: item.id,
        title: safeText(item.title, '未命名打卡'),
        target: safeText(item.target, '每日坚持完成'),
        days: finalDays,
        targetDays: finalTargetDays,
        date: normalizeDateInput(safeText(item.date, getToday())),
        startTime: safeText(item.startTime, '未设置'),
        endTime: safeText(item.endTime, '未设置'),
        checkedDate: safeText(item.checkedDate, ''),
        checkedDates: finalCheckedDates,
        createDate: normalizeDateInput(safeText(item.createDate, getToday()))
      })
    })

    return result
  }

  normalizeFocusRecords(list: FocusRecord[]): FocusRecord[] {
    let result: FocusRecord[] = []

    list.forEach((item: FocusRecord) => {
      result.push({
        id: item.id,
        taskId: item.taskId,
        taskTitle: safeText(item.taskTitle, '自由专注'),
        durationMinutes: item.durationMinutes,
        date: normalizeDateInput(safeText(item.date, getToday())),
        startTime: safeText(item.startTime, '未设置'),
        endTime: safeText(item.endTime, '未设置'),
        createTime: item.createTime
      })
    })

    return result
  }

  getDoneTaskCount(): number {
    return this.tasks.filter((item: TodoTask) => {
      return item.done
    }).length
  }

  getUndoneTaskCount(): number {
    return this.tasks.filter((item: TodoTask) => {
      return !item.done
    }).length
  }

  getTaskRate(): number {
    if (this.tasks.length === 0) {
      return 0
    }

    return Math.round(this.getDoneTaskCount() * 100 / this.tasks.length)
  }

  getTaskRateText(): string {
    return this.getTaskRate().toString() + '%'
  }

  isCheckCheckedToday(check: HabitData): boolean {
    if (check.checkedDates !== undefined && check.checkedDates !== null) {
      return check.checkedDates.indexOf(getToday()) >= 0
    }
    return normalizeDateInput(safeText(check.checkedDate, '')) === getToday()
  }

  getTodayCheckedCount(): number {
    return this.checks.filter((item: HabitData) => {
      return this.isCheckCheckedToday(item)
    }).length
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

  getCheckProgressText(check: HabitData): string {
    return this.getCheckProgressValue(check).toString() + '%'
  }

  getCheckProgressWidth(check: HabitData): string {
    return this.getCheckProgressValue(check).toString() + '%'
  }

  getTodayRecords(): FocusRecord[] {
    return this.focusRecords.filter((item: FocusRecord) => {
      return item.date === getToday()
    })
  }

  getTodayFocusCount(): number {
    return this.getTodayRecords().length
  }

  getTodayFocusMinutes(): number {
    let total = 0
    this.getTodayRecords().forEach((item: FocusRecord) => {
      total = total + item.durationMinutes
    })
    return total
  }

  getWeekRecords(): FocusRecord[] {
    let todayIndex = dateToDayNumber(getToday())
    return this.focusRecords.filter((item: FocusRecord) => {
      let itemIndex = dateToDayNumber(item.date)
      return itemIndex >= todayIndex - 6 && itemIndex <= todayIndex
    })
  }

  getWeekFocusCount(): number {
    return this.getWeekRecords().length
  }

  getWeekFocusMinutes(): number {
    let total = 0
    this.getWeekRecords().forEach((item: FocusRecord) => {
      total = total + item.durationMinutes
    })
    return total
  }

  getTotalFocusMinutes(): number {
    let total = 0
    this.focusRecords.forEach((item: FocusRecord) => {
      total = total + item.durationMinutes
    })
    return total
  }

  getReviewSuggestion(): string {
    if (this.tasks.length === 0 && this.checks.length === 0 && this.focusRecords.length === 0) {
      return '当前记录较少，建议先在计划页创建待办、便签或打卡，再使用专注页推进重点待办。'
    }

    if (this.getTaskRate() < 50 && this.tasks.length > 0) {
      return '待办完成率偏低，建议减少单日计划数量，把重要任务放到专注页中分段完成。'
    }

    if (this.getTodayFocusCount() === 0) {
      return '今天还没有专注记录，可以选择一个未完成待办，使用 25 分钟专注计时推进任务。'
    }

    if (this.checks.length > 0 && this.getTodayCheckedCount() === this.checks.length) {
      return '今天的打卡完成情况很好，可以继续保持，并在睡前补充一条便签记录复盘收获。'
    }

    return '整体使用情况较稳定。建议继续保持计划创建、专注执行、复盘查看的闭环。'
  }
}
