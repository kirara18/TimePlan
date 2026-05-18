import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'

interface TodoTask {
  id: number
  title: string
  priority: string
  date: string
  startTime: string
  endTime: string
  done: boolean
  createDate: string
}

interface NoteItem {
  id: number
  title: string
  content: string
  category: string
  date: string
  startTime: string
  endTime: string
  createDate: string
}

interface HabitData {
  id: number
  title: string
  target: string
  days: number
  targetDays: number
  date: string
  startTime: string
  endTime: string
  checkedDate: string
  checkedDates: string[]
  createDate: string
}

interface CalendarItem {
  id: number
  type: string
  title: string
  date: string
  startTime: string
  endTime: string
  description: string
  done: boolean
}

interface CalendarDay {
  date: string
  day: number
  isCurrentMonth: boolean
  isToday: boolean
  isSelected: boolean
  itemCount: number
  doneCount: number
}

@Entry
@Component
struct Index {
  @State currentIndex: number = 0
  @State themeColor: string = '#4F7CFF'

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
      TabContent() {
        CalendarPage({ themeColor: this.themeColor })
      }
      .tabBar('日历')

      TabContent() {
        PlanPage({ themeColor: this.themeColor })
      }
      .tabBar('计划')

      TabContent() {
        NotePage({ themeColor: this.themeColor })
      }
      .tabBar('便签')

      TabContent() {
        CheckPage({ themeColor: this.themeColor })
      }
      .tabBar('打卡')

      TabContent() {
        MinePage({
          themeColor: this.themeColor,
          onThemeChange: (color: string) => {
            this.themeColor = color
          }
        })
      }
      .tabBar('我的')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F7FB')
    .onChange((index: number) => {
      this.currentIndex = index
    })
  }
}

@Component
struct CalendarPage {
  @Prop themeColor: string = '#4F7CFF'

  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
  dataPreferences: preferences.Preferences | null = null

  readonly STORE_NAME: string = 'time_plan_store'
  readonly TASKS_KEY: string = 'plan_tasks'
  readonly NOTES_KEY: string = 'note_items'
  readonly HABITS_KEY: string = 'habit_items'

  @State currentYear: number = 2026
  @State currentMonth: number = 5
  @State selectedDate: string = ''
  @State allItems: CalendarItem[] = []
  @State calendarDays: CalendarDay[] = []
  @State operationTip: string = '点击日历中的日期，可查看当天详细安排'
  refreshTimerId: number = -1

  aboutToAppear(): void {
    let now = new Date()
    this.currentYear = now.getFullYear()
    this.currentMonth = now.getMonth() + 1
    this.selectedDate = this.getToday()

    this.initPreferencesAndLoad().then(() => {
      this.updateCalendarDays()
      this.startAutoRefresh()
    }).catch(() => {
      this.operationTip = '日历数据加载失败'
    })
  }

  aboutToDisappear(): void {
    this.stopAutoRefresh()
  }

  build() {
    Scroll() {
      Column() {
        Text('日历安排')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2937')
          .margin({ top: 30, bottom: 8 })

        Text('按月查看计划、便签、打卡中的全部安排')
          .fontSize(15)
          .fontColor('#6B7280')
          .margin({ bottom: 8 })

        Text(this.operationTip)
          .fontSize(13)
          .fontColor(this.themeColor)
          .margin({ bottom: 18 })

        Column() {
          Row() {
            Button('<')
              .width(44)
              .height(38)
              .fontSize(18)
              .backgroundColor(this.themeColor)
              .borderRadius(12)
              .onClick(() => {
                this.goPreviousMonth()
              })

            Blank()

            Text(this.getMonthTitle())
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111827')

            Blank()

            Button('>')
              .width(44)
              .height(38)
              .fontSize(18)
              .backgroundColor(this.themeColor)
              .borderRadius(12)
              .onClick(() => {
                this.goNextMonth()
              })
          }
          .width('100%')
          .margin({ bottom: 16 })

          Row() {
            ForEach(this.getWeekTitles(), (item: string) => {
              Text(item)
                .width('14.28%')
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor('#6B7280')
                .textAlign(TextAlign.Center)
            }, (item: string) => item)
          }
          .width('100%')
          .margin({ bottom: 8 })

          Grid() {
            ForEach(this.calendarDays, (day: CalendarDay) => {
              GridItem() {
                this.CalendarDayCell(day)
              }
            }, (day: CalendarDay) => day.date + '_' + day.itemCount.toString() + '_' + day.doneCount.toString() + '_' + day.isSelected.toString())
          }
          .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
          .rowsGap(8)
          .columnsGap(6)
          .width('100%')
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .margin({ bottom: 18 })

        Column() {
          Text('当月概览')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')
            .margin({ bottom: 14 })

          Row() {
            StatBox({ themeColor: this.themeColor, title: '全部', value: this.getMonthItemCount().toString() })
            StatBox({ themeColor: this.themeColor, title: '计划', value: this.getMonthTypeCount('计划').toString() })
            StatBox({ themeColor: this.themeColor, title: '打卡', value: this.getMonthTypeCount('打卡').toString() })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .margin({ bottom: 18 })

        Column() {
          Text(this.selectedDate + ' 的详细安排')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')
            .margin({ bottom: 12 })

          if (this.getSelectedDayItems().length === 0) {
            Column() {
              Text('这一天暂无安排')
                .fontSize(16)
                .fontColor('#9CA3AF')
                .margin({ top: 20, bottom: 20 })

              Text('请到计划、便签、打卡页新增带日期和时间的内容')
                .fontSize(13)
                .fontColor('#9CA3AF')
                .margin({ bottom: 20 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          } else {
            ForEach(this.getSelectedDayItems(), (item: CalendarItem) => {
              this.CalendarCard(item)
            }, (item: CalendarItem) => item.type + '_' + item.id.toString() + '_' + item.date + '_' + item.startTime + '_' + item.endTime + '_' + item.done.toString() + '_' + item.description)
          }
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .margin({ bottom: 30 })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F7FB')
  }

  @Builder
  CalendarDayCell(day: CalendarDay) {
    Column() {
      Text(day.day.toString())
        .fontSize(16)
        .fontWeight(day.isSelected ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.getDayTextColor(day))
        .margin({ top: 6 })

      if (day.itemCount > 0) {
        Text(day.itemCount.toString() + '项')
          .fontSize(10)
          .fontColor(day.isSelected ? '#FFFFFF' : this.themeColor)
          .margin({ top: 2 })
      } else {
        Text('')
          .fontSize(10)
          .margin({ top: 2 })
      }

      if (day.doneCount > 0) {
        Text(day.doneCount.toString() + '完成')
          .fontSize(9)
          .fontColor(day.isSelected ? '#FFFFFF' : '#22C55E')
          .margin({ top: 1 })
      } else if (day.isToday) {
        Text('今天')
          .fontSize(9)
          .fontColor(day.isSelected ? '#FFFFFF' : '#22C55E')
          .margin({ top: 1 })
      } else {
        Text('')
          .fontSize(9)
          .margin({ top: 1 })
      }
    }
    .width('100%')
    .height(66)
    .justifyContent(FlexAlign.Start)
    .backgroundColor(day.isSelected ? this.themeColor : (day.itemCount > 0 ? '#EEF2FF' : '#F9FAFB'))
    .borderRadius(12)
    .opacity(day.isCurrentMonth ? 1 : 0.35)
    .onClick(() => {
      this.selectedDate = day.date
      this.currentYear = this.getYearFromDate(day.date)
      this.currentMonth = this.getMonthFromDate(day.date)
      this.updateCalendarDays()
      this.operationTip = '已选择：' + day.date
    })
  }

  @Builder
  CalendarCard(item: CalendarItem) {
    Row() {
      Column() {
        Text(item.startTime + ' - ' + item.endTime)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColor)

        Text(item.type)
          .fontSize(12)
          .fontColor('#6B7280')
          .margin({ top: 4 })
      }
      .width(82)
      .alignItems(HorizontalAlign.Start)

      Column() {
        Row() {
          Text(item.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(item.done ? '#9CA3AF' : '#111827')
            .layoutWeight(1)

          if (item.type !== '便签') {
            Text(item.done ? '已完成' : '未完成')
              .fontSize(12)
              .fontColor(item.done ? '#22C55E' : '#EF4444')
              .backgroundColor(item.done ? '#DCFCE7' : '#FEE2E2')
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .borderRadius(8)
          }
        }
        .width('100%')

        Text(item.description)
          .fontSize(13)
          .fontColor('#6B7280')
          .margin({ top: 6 })

        if (item.done && item.type === '计划') {
          Text('该计划已在计划页标记完成')
            .fontSize(12)
            .fontColor('#22C55E')
            .margin({ top: 6 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(item.done ? '#F0FDF4' : '#F9FAFB')
    .borderRadius(12)
    .margin({ bottom: 10 })
  }

  async initPreferencesAndLoad(): Promise<void> {
    await this.initPreferences()
    await this.loadCalendarItems()
  }

  async initPreferences(): Promise<void> {
    if (this.dataPreferences !== null) {
      return
    }

    this.dataPreferences = await preferences.getPreferences(this.context, {
      name: this.STORE_NAME
    })
  }

  startAutoRefresh(): void {
    if (this.refreshTimerId !== -1) {
      return
    }

    this.refreshTimerId = setInterval(() => {
      this.loadCalendarItems().then(() => {
        this.updateCalendarDays()
        this.operationTip = '日历已自动同步'
      }).catch(() => {
        this.operationTip = '日历自动同步失败'
      })
    }, 800)
  }

  stopAutoRefresh(): void {
    if (this.refreshTimerId !== -1) {
      clearInterval(this.refreshTimerId)
      this.refreshTimerId = -1
    }
  }

  async loadCalendarItems(): Promise<void> {
    this.dataPreferences = await preferences.getPreferences(this.context, {
      name: this.STORE_NAME
    })

    if (this.dataPreferences === null) {
      return
    }

    let result: CalendarItem[] = []

    let tasksValue = await this.dataPreferences.get(this.TASKS_KEY, '')
    if (typeof tasksValue === 'string' && tasksValue.length > 0) {
      try {
        let tasks = JSON.parse(tasksValue) as TodoTask[]
        tasks.forEach((task: TodoTask) => {
          result.push({
            id: task.id,
            type: '计划',
            title: task.title,
            date: this.normalizeDateInput(this.safeText(task.date, this.getToday())),
            startTime: this.safeText(task.startTime, '未设置'),
            endTime: this.safeText(task.endTime, '未设置'),
            description: '优先级：' + this.safeText(task.priority, '中') + '，状态：' + (task.done ? '已完成' : '未完成'),
            done: task.done
          })
        })
      } catch (err) {
        console.error('读取计划日历失败')
      }
    }

    let notesValue = await this.dataPreferences.get(this.NOTES_KEY, '')
    if (typeof notesValue === 'string' && notesValue.length > 0) {
      try {
        let notes = JSON.parse(notesValue) as NoteItem[]
        notes.forEach((note: NoteItem) => {
          result.push({
            id: note.id,
            type: '便签',
            title: note.title,
            date: this.normalizeDateInput(this.safeText(note.date, this.getToday())),
            startTime: this.safeText(note.startTime, '未设置'),
            endTime: this.safeText(note.endTime, '未设置'),
            description: this.safeText(note.content, '暂无内容'),
            done: false
          })
        })
      } catch (err) {
        console.error('读取便签日历失败')
      }
    }

    let habitsValue = await this.dataPreferences.get(this.HABITS_KEY, '')
    if (typeof habitsValue === 'string' && habitsValue.length > 0) {
      try {
        let habits = JSON.parse(habitsValue) as HabitData[]
        habits.forEach((habit: HabitData) => {
          let startDate = this.normalizeDateInput(this.safeText(habit.date, this.getToday()))
          let checkedDates = this.getHabitCheckedDates(habit)
          let scheduleDates = this.getHabitScheduleDates(startDate, habit.targetDays, checkedDates)

          scheduleDates.forEach((dateText: string) => {
            result.push({
              id: habit.id,
              type: '打卡',
              title: habit.title,
              date: dateText,
              startTime: this.safeText(habit.startTime, '未设置'),
              endTime: this.safeText(habit.endTime, '未设置'),
              description: '目标：' + this.safeText(habit.target, '每日坚持完成') + '，已打卡：' + habit.days.toString() + '/' + habit.targetDays.toString() + ' 天；漏打日期会自动顺延',
              done: this.dateInList(dateText, checkedDates)
            })
          })
        })
      } catch (err) {
        console.error('读取打卡日历失败')
      }
    }

    this.allItems = result
  }

  updateCalendarDays(): void {
    let list: CalendarDay[] = []

    let firstWeek = new Date(this.currentYear, this.currentMonth - 1, 1).getDay()
    let daysInMonth = new Date(this.currentYear, this.currentMonth, 0).getDate()
    let prevYear = this.currentMonth === 1 ? this.currentYear - 1 : this.currentYear
    let prevMonth = this.currentMonth === 1 ? 12 : this.currentMonth - 1
    let nextYear = this.currentMonth === 12 ? this.currentYear + 1 : this.currentYear
    let nextMonth = this.currentMonth === 12 ? 1 : this.currentMonth + 1
    let daysInPrevMonth = new Date(prevYear, prevMonth, 0).getDate()

    for (let i = 0; i < 42; i++) {
      let finalYear = this.currentYear
      let finalMonth = this.currentMonth
      let finalDay = 1
      let isCurrent = true

      if (i < firstWeek) {
        finalYear = prevYear
        finalMonth = prevMonth
        finalDay = daysInPrevMonth - firstWeek + i + 1
        isCurrent = false
      } else if (i >= firstWeek + daysInMonth) {
        finalYear = nextYear
        finalMonth = nextMonth
        finalDay = i - firstWeek - daysInMonth + 1
        isCurrent = false
      } else {
        finalDay = i - firstWeek + 1
      }

      let dateText = this.formatDate(finalYear, finalMonth, finalDay)
      list.push({
        date: dateText,
        day: finalDay,
        isCurrentMonth: isCurrent,
        isToday: dateText === this.getToday(),
        isSelected: dateText === this.selectedDate,
        itemCount: this.getItemCountByDate(dateText),
        doneCount: this.getDoneCountByDate(dateText)
      })
    }

    this.calendarDays = list
  }

  goPreviousMonth(): void {
    if (this.currentMonth === 1) {
      this.currentYear = this.currentYear - 1
      this.currentMonth = 12
    } else {
      this.currentMonth = this.currentMonth - 1
    }

    this.selectedDate = this.formatDate(this.currentYear, this.currentMonth, 1)
    this.updateCalendarDays()
  }

  goNextMonth(): void {
    if (this.currentMonth === 12) {
      this.currentYear = this.currentYear + 1
      this.currentMonth = 1
    } else {
      this.currentMonth = this.currentMonth + 1
    }

    this.selectedDate = this.formatDate(this.currentYear, this.currentMonth, 1)
    this.updateCalendarDays()
  }

  getSelectedDayItems(): CalendarItem[] {
    let list = this.allItems.filter((item: CalendarItem) => {
      return item.date === this.selectedDate
    })

    list.sort((a: CalendarItem, b: CalendarItem) => {
      if (a.startTime > b.startTime) {
        return 1
      }
      if (a.startTime < b.startTime) {
        return -1
      }
      return 0
    })

    return list
  }

  getItemCountByDate(date: string): number {
    return this.allItems.filter((item: CalendarItem) => {
      return item.date === date
    }).length
  }

  getDoneCountByDate(date: string): number {
    return this.allItems.filter((item: CalendarItem) => {
      return item.date === date && item.done
    }).length
  }

  getMonthItemCount(): number {
    let monthText = this.formatMonth(this.currentYear, this.currentMonth)
    return this.allItems.filter((item: CalendarItem) => {
      return item.date.startsWith(monthText)
    }).length
  }

  getMonthTypeCount(type: string): number {
    let monthText = this.formatMonth(this.currentYear, this.currentMonth)
    return this.allItems.filter((item: CalendarItem) => {
      return item.date.startsWith(monthText) && item.type === type
    }).length
  }

  getDayTextColor(day: CalendarDay): string {
    if (day.isSelected) {
      return '#FFFFFF'
    }

    if (day.isToday) {
      return '#22C55E'
    }

    if (!day.isCurrentMonth) {
      return '#9CA3AF'
    }

    return '#111827'
  }

  getWeekTitles(): string[] {
    return ['日', '一', '二', '三', '四', '五', '六']
  }

  getMonthTitle(): string {
    return this.currentYear.toString() + '年' + this.currentMonth.toString() + '月'
  }

  getYearFromDate(date: string): number {
    return Number(date.substring(0, 4))
  }

  getMonthFromDate(date: string): number {
    return Number(date.substring(5, 7))
  }

  formatDate(year: number, month: number, day: number): string {
    let monthText = month < 10 ? '0' + month.toString() : month.toString()
    let dayText = day < 10 ? '0' + day.toString() : day.toString()
    return year.toString() + '-' + monthText + '-' + dayText
  }

  formatMonth(year: number, month: number): string {
    let monthText = month < 10 ? '0' + month.toString() : month.toString()
    return year.toString() + '-' + monthText
  }

  normalizeDateInput(value: string): string {
    let raw = this.safeText(value, '').trim()

    if (raw.length === 0 || raw === '未设置') {
      return this.getToday()
    }

    if (raw === '今天') {
      return this.getToday()
    }

    if (raw === '明天') {
      return this.addDays(this.getToday(), 1)
    }

    raw = raw.replace('年', '-')
    raw = raw.replace('月', '-')
    raw = raw.replace('日', '')
    raw = raw.replace('号', '')
    raw = raw.replace('/', '-')
    raw = raw.replace('.', '-')

    let parts = raw.split('-')

    if (parts.length === 1) {
      let day = Number(parts[0])
      if (!isNaN(day) && day >= 1 && day <= 31) {
        return this.formatDate(this.currentYear, this.currentMonth, Math.floor(day))
      }
    }

    if (parts.length === 2) {
      let month = Number(parts[0])
      let day = Number(parts[1])
      if (!isNaN(month) && !isNaN(day)) {
        return this.formatDate(this.currentYear, Math.floor(month), Math.floor(day))
      }
    }

    if (parts.length >= 3) {
      let year = Number(parts[0])
      let month = Number(parts[1])
      let day = Number(parts[2])
      if (!isNaN(year) && !isNaN(month) && !isNaN(day)) {
        return this.formatDate(Math.floor(year), Math.floor(month), Math.floor(day))
      }
    }

    return this.getToday()
  }

  getHabitCheckedDates(habit: HabitData): string[] {
    let result: string[] = []

    if (habit.checkedDates !== undefined && habit.checkedDates !== null) {
      habit.checkedDates.forEach((dateText: string) => {
        let normalized = this.normalizeDateInput(dateText)
        if (!this.dateInList(normalized, result)) {
          result.push(normalized)
        }
      })
    }

    if (habit.checkedDate !== undefined && habit.checkedDate !== null && habit.checkedDate.length > 0) {
      let normalizedCheckedDate = this.normalizeDateInput(habit.checkedDate)
      if (!this.dateInList(normalizedCheckedDate, result)) {
        result.push(normalizedCheckedDate)
      }
    }

    return result
  }

  getHabitScheduleDates(startDate: string, targetDays: number, checkedDates: string[]): string[] {
    let result: string[] = []
    let finalTargetDays = targetDays

    if (finalTargetDays <= 0) {
      finalTargetDays = 30
    }

    let startIndex = this.dateToDayNumber(startDate)
    let todayIndex = this.dateToDayNumber(this.getToday())

    let checkedBeforeToday = 0
    checkedDates.forEach((dateText: string) => {
      let dateIndex = this.dateToDayNumber(dateText)
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

    let endIndex = startIndex + finalTargetDays + missedBeforeToday - 1

    if (checkedDates.length >= finalTargetDays) {
      let lastCheckedIndex = startIndex
      checkedDates.forEach((dateText: string) => {
        let dateIndex = this.dateToDayNumber(dateText)
        if (dateIndex > lastCheckedIndex) {
          lastCheckedIndex = dateIndex
        }
      })
      endIndex = lastCheckedIndex
    }

    for (let i = startIndex; i <= endIndex; i++) {
      result.push(this.dayNumberToDate(i))
    }

    return result
  }

  dateInList(dateText: string, list: string[]): boolean {
    return list.indexOf(dateText) >= 0
  }

  dateToDayNumber(dateText: string): number {
    let year = Number(dateText.substring(0, 4))
    let month = Number(dateText.substring(5, 7))
    let day = Number(dateText.substring(8, 10))

    // 使用 UTC 计算“日期序号”，避免中国时区下 17 号被换算成 16 号的问题。
    let time = Date.UTC(year, month - 1, day)
    return Math.floor(time / 86400000)
  }

  dayNumberToDate(dayNumber: number): string {
    // 使用 UTC 读取年月日，保证日期加减不受本地时区影响。
    let date = new Date(dayNumber * 86400000)
    let year = date.getUTCFullYear()
    let month = date.getUTCMonth() + 1
    let day = date.getUTCDate()
    return this.formatDate(year, month, day)
  }

  addDays(dateText: string, count: number): string {
    return this.dayNumberToDate(this.dateToDayNumber(dateText) + count)
  }

  safeText(value: string, defaultValue: string): string {
    if (value === undefined || value === null || value.length === 0) {
      return defaultValue
    }
    return value
  }

  getToday(): string {
    let date = new Date()
    let year = date.getFullYear()
    let month = date.getMonth() + 1
    let day = date.getDate()

    let monthText = month < 10 ? '0' + month.toString() : month.toString()
    let dayText = day < 10 ? '0' + day.toString() : day.toString()

    return year.toString() + '-' + monthText + '-' + dayText
  }
}
@Component
struct PlanPage {
  @Prop themeColor: string = '#4F7CFF'

  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
  dataPreferences: preferences.Preferences | null = null

  readonly STORE_NAME: string = 'time_plan_store'
  readonly TASKS_KEY: string = 'plan_tasks'
  readonly TASK_NEXT_ID_KEY: string = 'plan_tasks_next_id'

  @State showAddPanel: boolean = false
  @State taskTitle: string = ''
  @State taskPriority: string = ''
  @State taskDate: string = ''
  @State taskStartTime: string = ''
  @State taskEndTime: string = ''
  @State taskSearchText: string = ''

  @State taskNextId: number = 4
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

  aboutToAppear(): void {
    this.initPreferencesAndLoad().then(() => {
      console.info('计划页数据加载完成')
    }).catch(() => {
      console.error('计划页数据加载失败')
    })
  }

  build() {
    Scroll() {
      Column() {
        Text('计划')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2937')
          .margin({ top: 30, bottom: 8 })

        Text('建立待办时填写日期、开始时间和结束时间')
          .fontSize(15)
          .fontColor('#6B7280')
          .margin({ bottom: 20 })

        TextInput({ text: this.taskSearchText, placeholder: '搜索待办任务...' })
          .width('100%')
          .height(44)
          .backgroundColor('#FFFFFF')
          .borderRadius(14)
          .padding({ left: 14, right: 14 })
          .margin({ bottom: 20 })
          .onChange((value: string) => {
            this.taskSearchText = value
          })

        Column() {
          Text('任务概览')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')
            .margin({ bottom: 14 })

          Row() {
            StatBox({ themeColor: this.themeColor, title: '总数', value: this.tasks.length.toString() })
            StatBox({ themeColor: this.themeColor, title: '已完成', value: this.getDoneCount().toString() })
            StatBox({ themeColor: this.themeColor, title: '未完成', value: this.getUndoneCount().toString() })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .margin({ bottom: 18 })

        Button(this.showAddPanel ? '收起新增任务' : '+ 新增待办')
          .width('100%')
          .height(48)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(this.themeColor)
          .borderRadius(16)
          .margin({ bottom: 14 })
          .onClick(() => {
            this.showAddPanel = !this.showAddPanel
            if (this.taskDate.trim().length === 0) {
              this.taskDate = this.getToday()
            }
          })

        if (this.showAddPanel) {
          Column() {
            Text('新增待办任务')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111827')
              .margin({ bottom: 12 })

            TextInput({ text: this.taskTitle, placeholder: '请输入任务名称，例如：完成课程报告' })
              .width('100%')
              .height(44)
              .backgroundColor('#F9FAFB')
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.taskTitle = value
              })

            TextInput({ text: this.taskPriority, placeholder: '请输入优先级：高 / 中 / 低' })
              .width('100%')
              .height(44)
              .backgroundColor('#F9FAFB')
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.taskPriority = value
              })

            TextInput({ text: this.taskDate, placeholder: '请输入日期，例如：2026-05-17 或 19' })
              .width('100%')
              .height(44)
              .backgroundColor('#F9FAFB')
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.taskDate = value
              })

            Row() {
              TextInput({ text: this.taskStartTime, placeholder: '开始 09:00' })
                .layoutWeight(1)
                .height(44)
                .backgroundColor('#F9FAFB')
                .borderRadius(12)
                .padding({ left: 12, right: 12 })
                .margin({ right: 6 })
                .onChange((value: string) => {
                  this.taskStartTime = value
                })

              TextInput({ text: this.taskEndTime, placeholder: '结束 10:00' })
                .layoutWeight(1)
                .height(44)
                .backgroundColor('#F9FAFB')
                .borderRadius(12)
                .padding({ left: 12, right: 12 })
                .margin({ left: 6 })
                .onChange((value: string) => {
                  this.taskEndTime = value
                })
            }
            .width('100%')
            .margin({ bottom: 14 })

            Button('保存待办')
              .width('100%')
              .height(44)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .backgroundColor('#22C55E')
              .borderRadius(12)
              .onClick(() => {
                this.addTask()
              })
          }
          .width('100%')
          .padding(18)
          .backgroundColor('#FFFFFF')
          .borderRadius(18)
          .margin({ bottom: 18 })
        }

        Column() {
          Text('待办任务')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')
            .margin({ bottom: 12 })

          if (this.getFilteredTasks().length === 0) {
            Column() {
              Text('暂无匹配任务')
                .fontSize(16)
                .fontColor('#9CA3AF')
                .margin({ top: 20, bottom: 20 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          } else {
            ForEach(this.getFilteredTasks(), (item: TodoTask) => {
              this.TaskCard(item)
            }, (item: TodoTask) => item.id.toString() + '_' + item.done.toString() + '_' + item.date + '_' + item.startTime)
          }
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .margin({ bottom: 30 })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F7FB')
  }

  @Builder
  TaskCard(task: TodoTask) {
    Column() {
      Row() {
        Text(task.done ? '✓' : '○')
          .fontSize(24)
          .fontColor(task.done ? '#22C55E' : '#9CA3AF')
          .margin({ right: 10 })

        Column() {
          Text(task.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(task.done ? '#9CA3AF' : '#111827')

          Text('日期：' + this.safeText(task.date, '未设置') + '    时间：' + this.safeText(task.startTime, '未设置') + ' - ' + this.safeText(task.endTime, '未设置'))
            .fontSize(13)
            .fontColor(this.themeColor)
            .margin({ top: 4 })

          Text('优先级：' + task.priority + '    状态：' + (task.done ? '已完成' : '未完成'))
            .fontSize(12)
            .fontColor('#6B7280')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .margin({ bottom: 12 })

      Row() {
        Button(task.done ? '恢复' : '完成')
          .layoutWeight(1)
          .height(38)
          .fontSize(14)
          .backgroundColor(task.done ? '#9CA3AF' : '#22C55E')
          .borderRadius(12)
          .margin({ right: 8 })
          .onClick(() => {
            this.toggleTask(task.id)
          })

        Button('删除')
          .layoutWeight(1)
          .height(38)
          .fontSize(14)
          .backgroundColor('#EF4444')
          .borderRadius(12)
          .margin({ left: 8 })
          .onClick(() => {
            this.deleteTask(task.id)
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(task.done ? '#F0FDF4' : '#F9FAFB')
    .borderRadius(12)
    .margin({ bottom: 10 })
  }

  async initPreferencesAndLoad(): Promise<void> {
    await this.initPreferences()
    await this.loadTasks()
  }

  async initPreferences(): Promise<void> {
    if (this.dataPreferences !== null) {
      return
    }

    this.dataPreferences = await preferences.getPreferences(this.context, {
      name: this.STORE_NAME
    })
  }

  async loadTasks(): Promise<void> {
    if (this.dataPreferences === null) {
      return
    }

    let tasksValue = await this.dataPreferences.get(this.TASKS_KEY, '')
    if (typeof tasksValue === 'string' && tasksValue.length > 0) {
      try {
        let parsedTasks = JSON.parse(tasksValue) as TodoTask[]
        this.tasks = this.normalizeTasks(parsedTasks)
      } catch (err) {
        console.error('读取待办失败')
      }
    }

    let nextIdValue = await this.dataPreferences.get(this.TASK_NEXT_ID_KEY, 4)
    if (typeof nextIdValue === 'number') {
      this.taskNextId = nextIdValue
    }
  }

  normalizeTasks(list: TodoTask[]): TodoTask[] {
    let result: TodoTask[] = []
    list.forEach((item: TodoTask) => {
      result.push({
        id: item.id,
        title: item.title,
        priority: this.safeText(item.priority, '中'),
        date: this.normalizeDateInput(this.safeText(item.date, this.getToday())),
        startTime: this.safeText(item.startTime, '未设置'),
        endTime: this.safeText(item.endTime, '未设置'),
        done: item.done,
        createDate: this.safeText(item.createDate, this.getToday())
      })
    })
    return result
  }

  async saveTasks(): Promise<void> {
    if (this.dataPreferences === null) {
      await this.initPreferences()
    }

    if (this.dataPreferences === null) {
      return
    }

    await this.dataPreferences.put(this.TASKS_KEY, JSON.stringify(this.tasks))
    await this.dataPreferences.put(this.TASK_NEXT_ID_KEY, this.taskNextId)
    await this.dataPreferences.flush()
  }

  getFilteredTasks(): TodoTask[] {
    if (this.taskSearchText.trim().length === 0) {
      return this.tasks
    }

    let keyword = this.taskSearchText.trim().toLowerCase()

    return this.tasks.filter((item: TodoTask) => {
      return item.title.toLowerCase().includes(keyword)
        || item.priority.toLowerCase().includes(keyword)
        || item.date.toLowerCase().includes(keyword)
        || item.startTime.toLowerCase().includes(keyword)
        || item.endTime.toLowerCase().includes(keyword)
    })
  }

  addTask(): void {
    if (this.taskTitle.trim().length === 0) {
      return
    }

    let newTask: TodoTask = {
      id: this.taskNextId,
      title: this.taskTitle,
      priority: this.taskPriority.trim().length === 0 ? '中' : this.taskPriority,
      date: this.normalizeDateInput(this.taskDate),
      startTime: this.taskStartTime.trim().length === 0 ? '未设置' : this.taskStartTime,
      endTime: this.taskEndTime.trim().length === 0 ? '未设置' : this.taskEndTime,
      done: false,
      createDate: this.getToday()
    }

    this.tasks = [newTask, ...this.tasks]
    this.taskNextId = this.taskNextId + 1

    this.taskTitle = ''
    this.taskPriority = ''
    this.taskDate = this.getToday()
    this.taskStartTime = ''
    this.taskEndTime = ''
    this.showAddPanel = false

    this.saveTasks().then(() => {
      console.info('待办保存成功')
    }).catch(() => {
      console.error('待办保存失败')
    })
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
      console.info('待办完成状态已保存')
    }).catch(() => {
      console.error('待办完成状态保存失败')
    })
  }

  deleteTask(id: number): void {
    this.tasks = this.tasks.filter((item: TodoTask) => {
      return item.id !== id
    })

    this.saveTasks().then(() => {
      console.info('待办删除后已保存')
    }).catch(() => {
      console.error('待办删除后保存失败')
    })
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

  normalizeDateInput(value: string): string {
    let raw = this.safeText(value, '').trim()

    if (raw.length === 0 || raw === '未设置') {
      return this.getToday()
    }

    if (raw === '今天') {
      return this.getToday()
    }

    if (raw === '明天') {
      return this.addDays(this.getToday(), 1)
    }

    raw = raw.replace('年', '-')
    raw = raw.replace('月', '-')
    raw = raw.replace('日', '')
    raw = raw.replace('号', '')
    raw = raw.replace('/', '-')
    raw = raw.replace('.', '-')

    let parts = raw.split('-')

    if (parts.length === 1) {
      let day = Number(parts[0])
      if (!isNaN(day) && day >= 1 && day <= 31) {
        let now = new Date()
        return this.formatDate(now.getFullYear(), now.getMonth() + 1, Math.floor(day))
      }
    }

    if (parts.length === 2) {
      let month = Number(parts[0])
      let day = Number(parts[1])
      if (!isNaN(month) && !isNaN(day)) {
        let now = new Date()
        return this.formatDate(now.getFullYear(), Math.floor(month), Math.floor(day))
      }
    }

    if (parts.length >= 3) {
      let year = Number(parts[0])
      let month = Number(parts[1])
      let day = Number(parts[2])
      if (!isNaN(year) && !isNaN(month) && !isNaN(day)) {
        return this.formatDate(Math.floor(year), Math.floor(month), Math.floor(day))
      }
    }

    return this.getToday()
  }

  addDays(dateText: string, count: number): string {
    let year = Number(dateText.substring(0, 4))
    let month = Number(dateText.substring(5, 7))
    let day = Number(dateText.substring(8, 10))
    let date = new Date(year, month - 1, day + count)
    return this.formatDate(date.getFullYear(), date.getMonth() + 1, date.getDate())
  }

  formatDate(year: number, month: number, day: number): string {
    let monthText = month < 10 ? '0' + month.toString() : month.toString()
    let dayText = day < 10 ? '0' + day.toString() : day.toString()
    return year.toString() + '-' + monthText + '-' + dayText
  }

  safeText(value: string, defaultValue: string): string {
    if (value === undefined || value === null || value.length === 0) {
      return defaultValue
    }
    return value
  }

  getToday(): string {
    let date = new Date()
    let year = date.getFullYear()
    let month = date.getMonth() + 1
    let day = date.getDate()

    let monthText = month < 10 ? '0' + month.toString() : month.toString()
    let dayText = day < 10 ? '0' + day.toString() : day.toString()

    return year.toString() + '-' + monthText + '-' + dayText
  }
}

@Component
struct NotePage {
  @Prop themeColor: string = '#4F7CFF'
  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
  dataPreferences: preferences.Preferences | null = null

  readonly STORE_NAME: string = 'time_plan_store'
  readonly NOTES_KEY: string = 'note_items'
  readonly NOTE_NEXT_ID_KEY: string = 'note_items_next_id'

  @State showAddPanel: boolean = false
  @State noteSearchText: string = ''
  @State noteTitle: string = ''
  @State noteContent: string = ''
  @State noteCategory: string = ''
  @State noteDate: string = ''
  @State noteStartTime: string = ''
  @State noteEndTime: string = ''
  @State transferTip: string = '便签可设置日期和时间，并同步显示到日历页'

  @State noteNextId: number = 3
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

  aboutToAppear(): void {
    this.initPreferencesAndLoad().then(() => {
      console.info('便签页数据加载完成')
    }).catch(() => {
      console.error('便签页数据加载失败')
    })
  }

  build() {
    Scroll() {
      Column() {
        Text('便签')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2937')
          .margin({ top: 30, bottom: 8 })

        Text('建立便签时可以填写日期与时间')
          .fontSize(15)
          .fontColor('#6B7280')
          .margin({ bottom: 8 })

        Text(this.transferTip)
          .fontSize(13)
          .fontColor(this.themeColor)
          .margin({ bottom: 20 })

        TextInput({ text: this.noteSearchText, placeholder: '搜索便签标题、内容或分类...' })
          .width('100%')
          .height(44)
          .backgroundColor('#FFFFFF')
          .borderRadius(14)
          .padding({ left: 14, right: 14 })
          .margin({ bottom: 20 })
          .onChange((value: string) => {
            this.noteSearchText = value
          })

        Column() {
          Text('便签概览')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')
            .margin({ bottom: 14 })

          Row() {
            StatBox({ themeColor: this.themeColor, title: '总数', value: this.notes.length.toString() })
            StatBox({ themeColor: this.themeColor, title: '学习', value: this.getCategoryCount('学习').toString() })
            StatBox({ themeColor: this.themeColor, title: '项目', value: this.getCategoryCount('项目').toString() })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .margin({ bottom: 18 })

        Button(this.showAddPanel ? '收起新建便签' : '+ 新建便签')
          .width('100%')
          .height(48)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(this.themeColor)
          .borderRadius(16)
          .margin({ bottom: 14 })
          .onClick(() => {
            this.showAddPanel = !this.showAddPanel
            if (this.noteDate.trim().length === 0) {
              this.noteDate = this.getToday()
            }
          })

        if (this.showAddPanel) {
          Column() {
            Text('新建便签')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111827')
              .margin({ bottom: 12 })

            TextInput({ text: this.noteTitle, placeholder: '请输入便签标题' })
              .width('100%')
              .height(44)
              .backgroundColor('#F9FAFB')
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.noteTitle = value
              })

            TextInput({ text: this.noteContent, placeholder: '请输入便签内容' })
              .width('100%')
              .height(90)
              .backgroundColor('#F9FAFB')
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.noteContent = value
              })

            TextInput({ text: this.noteCategory, placeholder: '请输入分类，例如：学习 / 项目 / 生活' })
              .width('100%')
              .height(44)
              .backgroundColor('#F9FAFB')
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.noteCategory = value
              })

            TextInput({ text: this.noteDate, placeholder: '请输入日期，例如：2026-05-17 或 19' })
              .width('100%')
              .height(44)
              .backgroundColor('#F9FAFB')
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.noteDate = value
              })

            Row() {
              TextInput({ text: this.noteStartTime, placeholder: '开始 09:00' })
                .layoutWeight(1)
                .height(44)
                .backgroundColor('#F9FAFB')
                .borderRadius(12)
                .padding({ left: 12, right: 12 })
                .margin({ right: 6 })
                .onChange((value: string) => {
                  this.noteStartTime = value
                })

              TextInput({ text: this.noteEndTime, placeholder: '结束 10:00' })
                .layoutWeight(1)
                .height(44)
                .backgroundColor('#F9FAFB')
                .borderRadius(12)
                .padding({ left: 12, right: 12 })
                .margin({ left: 6 })
                .onChange((value: string) => {
                  this.noteEndTime = value
                })
            }
            .width('100%')
            .margin({ bottom: 14 })

            Button('保存便签')
              .width('100%')
              .height(44)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .backgroundColor('#22C55E')
              .borderRadius(12)
              .onClick(() => {
                this.addNote()
              })
          }
          .width('100%')
          .padding(18)
          .backgroundColor('#FFFFFF')
          .borderRadius(18)
          .margin({ bottom: 18 })
        }

        Column() {
          Text('便签列表')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')
            .margin({ bottom: 12 })

          if (this.getFilteredNotes().length === 0) {
            Column() {
              Text('暂无匹配便签')
                .fontSize(16)
                .fontColor('#9CA3AF')
                .margin({ top: 20, bottom: 20 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          } else {
            ForEach(this.getFilteredNotes(), (item: NoteItem) => {
              this.NoteItemCard(item)
            }, (item: NoteItem) => item.id.toString())
          }
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .margin({ bottom: 30 })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F7FB')
  }

  @Builder
  NoteItemCard(note: NoteItem) {
    Column() {
      Row() {
        Text(note.title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111827')
          .layoutWeight(1)

        Text('#' + note.category)
          .fontSize(12)
          .fontColor(this.themeColor)
          .backgroundColor('#EEF2FF')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(8)
      }
      .width('100%')
      .margin({ bottom: 8 })

      Text(note.content)
        .fontSize(14)
        .fontColor('#6B7280')
        .margin({ bottom: 8 })

      Text('日期：' + this.safeText(note.date, '未设置') + '    时间：' + this.safeText(note.startTime, '未设置') + ' - ' + this.safeText(note.endTime, '未设置'))
        .fontSize(13)
        .fontColor(this.themeColor)
        .margin({ bottom: 12 })

      Button('删除')
        .width('100%')
        .height(36)
        .fontSize(13)
        .backgroundColor('#EF4444')
        .borderRadius(12)
        .onClick(() => {
          this.deleteNote(note.id)
        })
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#F9FAFB')
    .borderRadius(12)
    .margin({ bottom: 10 })
    .alignItems(HorizontalAlign.Start)
  }

  async initPreferencesAndLoad(): Promise<void> {
    await this.initPreferences()
    await this.loadNotes()
  }

  async initPreferences(): Promise<void> {
    if (this.dataPreferences !== null) {
      return
    }

    this.dataPreferences = await preferences.getPreferences(this.context, {
      name: this.STORE_NAME
    })
  }

  async loadNotes(): Promise<void> {
    if (this.dataPreferences === null) {
      return
    }

    let notesValue = await this.dataPreferences.get(this.NOTES_KEY, '')
    if (typeof notesValue === 'string' && notesValue.length > 0) {
      try {
        let parsedNotes = JSON.parse(notesValue) as NoteItem[]
        this.notes = this.normalizeNotes(parsedNotes)
      } catch (err) {
        console.error('读取便签失败')
      }
    }

    let nextIdValue = await this.dataPreferences.get(this.NOTE_NEXT_ID_KEY, 3)
    if (typeof nextIdValue === 'number') {
      this.noteNextId = nextIdValue
    }
  }

  normalizeNotes(list: NoteItem[]): NoteItem[] {
    let result: NoteItem[] = []
    list.forEach((item: NoteItem) => {
      result.push({
        id: item.id,
        title: item.title,
        content: this.safeText(item.content, '暂无内容'),
        category: this.safeText(item.category, '默认'),
        date: this.normalizeDateInput(this.safeText(item.date, this.getToday())),
        startTime: this.safeText(item.startTime, '未设置'),
        endTime: this.safeText(item.endTime, '未设置'),
        createDate: this.safeText(item.createDate, this.getToday())
      })
    })
    return result
  }

  async saveNotes(): Promise<void> {
    if (this.dataPreferences === null) {
      await this.initPreferences()
    }

    if (this.dataPreferences === null) {
      return
    }

    await this.dataPreferences.put(this.NOTES_KEY, JSON.stringify(this.notes))
    await this.dataPreferences.put(this.NOTE_NEXT_ID_KEY, this.noteNextId)
    await this.dataPreferences.flush()
  }


  getFilteredNotes(): NoteItem[] {
    if (this.noteSearchText.trim().length === 0) {
      return this.notes
    }

    let keyword = this.noteSearchText.trim().toLowerCase()

    return this.notes.filter((item: NoteItem) => {
      return item.title.toLowerCase().includes(keyword)
        || item.content.toLowerCase().includes(keyword)
        || item.category.toLowerCase().includes(keyword)
        || item.date.toLowerCase().includes(keyword)
        || item.startTime.toLowerCase().includes(keyword)
        || item.endTime.toLowerCase().includes(keyword)
    })
  }

  addNote(): void {
    if (this.noteTitle.trim().length === 0) {
      return
    }

    let newNote: NoteItem = {
      id: this.noteNextId,
      title: this.noteTitle,
      content: this.noteContent.trim().length === 0 ? '暂无内容' : this.noteContent,
      category: this.noteCategory.trim().length === 0 ? '默认' : this.noteCategory,
      date: this.normalizeDateInput(this.noteDate),
      startTime: this.noteStartTime.trim().length === 0 ? '未设置' : this.noteStartTime,
      endTime: this.noteEndTime.trim().length === 0 ? '未设置' : this.noteEndTime,
      createDate: this.getToday()
    }

    this.notes = [newNote, ...this.notes]
    this.noteNextId = this.noteNextId + 1

    this.noteTitle = ''
    this.noteContent = ''
    this.noteCategory = ''
    this.noteDate = this.getToday()
    this.noteStartTime = ''
    this.noteEndTime = ''
    this.showAddPanel = false

    this.saveNotes().then(() => {
      console.info('便签保存成功')
    }).catch(() => {
      console.error('便签保存失败')
    })
  }

  deleteNote(id: number): void {
    this.notes = this.notes.filter((item: NoteItem) => {
      return item.id !== id
    })

    this.saveNotes().then(() => {
      console.info('便签删除后已保存')
    }).catch(() => {
      console.error('便签删除后保存失败')
    })
  }

  getCategoryCount(category: string): number {
    return this.notes.filter((item: NoteItem) => {
      return item.category === category
    }).length
  }

  normalizeDateInput(value: string): string {
    let raw = this.safeText(value, '').trim()

    if (raw.length === 0 || raw === '未设置') {
      return this.getToday()
    }

    if (raw === '今天') {
      return this.getToday()
    }

    if (raw === '明天') {
      return this.addDays(this.getToday(), 1)
    }

    raw = raw.replace('年', '-')
    raw = raw.replace('月', '-')
    raw = raw.replace('日', '')
    raw = raw.replace('号', '')
    raw = raw.replace('/', '-')
    raw = raw.replace('.', '-')

    let parts = raw.split('-')

    if (parts.length === 1) {
      let day = Number(parts[0])
      if (!isNaN(day) && day >= 1 && day <= 31) {
        let now = new Date()
        return this.formatDate(now.getFullYear(), now.getMonth() + 1, Math.floor(day))
      }
    }

    if (parts.length === 2) {
      let month = Number(parts[0])
      let day = Number(parts[1])
      if (!isNaN(month) && !isNaN(day)) {
        let now = new Date()
        return this.formatDate(now.getFullYear(), Math.floor(month), Math.floor(day))
      }
    }

    if (parts.length >= 3) {
      let year = Number(parts[0])
      let month = Number(parts[1])
      let day = Number(parts[2])
      if (!isNaN(year) && !isNaN(month) && !isNaN(day)) {
        return this.formatDate(Math.floor(year), Math.floor(month), Math.floor(day))
      }
    }

    return this.getToday()
  }

  addDays(dateText: string, count: number): string {
    let year = Number(dateText.substring(0, 4))
    let month = Number(dateText.substring(5, 7))
    let day = Number(dateText.substring(8, 10))
    let date = new Date(year, month - 1, day + count)
    return this.formatDate(date.getFullYear(), date.getMonth() + 1, date.getDate())
  }

  formatDate(year: number, month: number, day: number): string {
    let monthText = month < 10 ? '0' + month.toString() : month.toString()
    let dayText = day < 10 ? '0' + day.toString() : day.toString()
    return year.toString() + '-' + monthText + '-' + dayText
  }

  safeText(value: string, defaultValue: string): string {
    if (value === undefined || value === null || value.length === 0) {
      return defaultValue
    }
    return value
  }

  getToday(): string {
    let date = new Date()
    let year = date.getFullYear()
    let month = date.getMonth() + 1
    let day = date.getDate()

    let monthText = month < 10 ? '0' + month.toString() : month.toString()
    let dayText = day < 10 ? '0' + day.toString() : day.toString()

    return year.toString() + '-' + monthText + '-' + dayText
  }
}

@Component
struct CheckPage {
  @Prop themeColor: string = '#4F7CFF'

  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
  dataPreferences: preferences.Preferences | null = null

  readonly STORE_NAME: string = 'time_plan_store'
  readonly HABITS_KEY: string = 'habit_items'
  readonly HABIT_NEXT_ID_KEY: string = 'habit_items_next_id'

  @State showAddPanel: boolean = false
  @State habitSearchText: string = ''
  @State habitTitle: string = ''
  @State habitTarget: string = ''
  @State habitTargetDaysText: string = ''
  @State habitDate: string = ''
  @State habitStartTime: string = ''
  @State habitEndTime: string = ''

  @State habitNextId: number = 4
  @State habits: HabitData[] = [
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
    this.initPreferencesAndLoad().then(() => {
      console.info('打卡页数据加载完成')
    }).catch(() => {
      console.error('打卡页数据加载失败')
    })
  }

  build() {
    Scroll() {
      Column() {
        Text('打卡 OKR')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2937')
          .margin({ top: 30, bottom: 8 })

        Text('建立习惯时填写日期、开始时间和结束时间')
          .fontSize(15)
          .fontColor('#6B7280')
          .margin({ bottom: 20 })

        TextInput({ text: this.habitSearchText, placeholder: '搜索习惯名称或目标...' })
          .width('100%')
          .height(44)
          .backgroundColor('#FFFFFF')
          .borderRadius(14)
          .padding({ left: 14, right: 14 })
          .margin({ bottom: 20 })
          .onChange((value: string) => {
            this.habitSearchText = value
          })

        Column() {
          Text('今日打卡概览')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')
            .margin({ bottom: 14 })

          Row() {
            StatBox({ themeColor: this.themeColor, title: '习惯', value: this.habits.length.toString() })
            StatBox({ themeColor: this.themeColor, title: '已打卡', value: this.getTodayCheckedCount().toString() })
            StatBox({ themeColor: this.themeColor, title: '今日率', value: this.getTodayRateText() })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .margin({ bottom: 18 })

        Button(this.showAddPanel ? '收起新增习惯' : '+ 新增习惯')
          .width('100%')
          .height(48)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(this.themeColor)
          .borderRadius(16)
          .margin({ bottom: 14 })
          .onClick(() => {
            this.showAddPanel = !this.showAddPanel
            if (this.habitDate.trim().length === 0) {
              this.habitDate = this.getToday()
            }
          })

        if (this.showAddPanel) {
          Column() {
            Text('新增习惯')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111827')
              .margin({ bottom: 12 })

            TextInput({ text: this.habitTitle, placeholder: '请输入习惯名称，例如：背单词' })
              .width('100%')
              .height(44)
              .backgroundColor('#F9FAFB')
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.habitTitle = value
              })

            TextInput({ text: this.habitTarget, placeholder: '请输入目标，例如：每天 20 个单词' })
              .width('100%')
              .height(44)
              .backgroundColor('#F9FAFB')
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.habitTarget = value
              })

            TextInput({ text: this.habitTargetDaysText, placeholder: '请输入计划打卡天数，例如：30' })
              .width('100%')
              .height(44)
              .backgroundColor('#F9FAFB')
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.habitTargetDaysText = value
              })

            TextInput({ text: this.habitDate, placeholder: '请输入日期，例如：2026-05-17 或 19' })
              .width('100%')
              .height(44)
              .backgroundColor('#F9FAFB')
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.habitDate = value
              })

            Row() {
              TextInput({ text: this.habitStartTime, placeholder: '开始 09:00' })
                .layoutWeight(1)
                .height(44)
                .backgroundColor('#F9FAFB')
                .borderRadius(12)
                .padding({ left: 12, right: 12 })
                .margin({ right: 6 })
                .onChange((value: string) => {
                  this.habitStartTime = value
                })

              TextInput({ text: this.habitEndTime, placeholder: '结束 10:00' })
                .layoutWeight(1)
                .height(44)
                .backgroundColor('#F9FAFB')
                .borderRadius(12)
                .padding({ left: 12, right: 12 })
                .margin({ left: 6 })
                .onChange((value: string) => {
                  this.habitEndTime = value
                })
            }
            .width('100%')
            .margin({ bottom: 14 })

            Button('保存习惯')
              .width('100%')
              .height(44)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .backgroundColor('#22C55E')
              .borderRadius(12)
              .onClick(() => {
                this.addHabit()
              })
          }
          .width('100%')
          .padding(18)
          .backgroundColor('#FFFFFF')
          .borderRadius(18)
          .margin({ bottom: 18 })
        }

        Column() {
          Text('习惯列表')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')
            .margin({ bottom: 12 })

          if (this.getFilteredHabits().length === 0) {
            Column() {
              Text('暂无匹配习惯')
                .fontSize(16)
                .fontColor('#9CA3AF')
                .margin({ top: 20, bottom: 20 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          } else {
            ForEach(this.getFilteredHabits(), (item: HabitData) => {
              this.HabitCard(item)
            }, (item: HabitData) => item.id.toString() + '_' + item.checkedDate + '_' + item.days.toString() + '_' + item.targetDays.toString())
          }
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .margin({ bottom: 30 })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F7FB')
  }

  @Builder
  HabitCard(habit: HabitData) {
    Column() {
      Row() {
        Text(this.isCheckedToday(habit) ? '✓' : '○')
          .fontSize(24)
          .fontColor(this.isCheckedToday(habit) ? '#22C55E' : '#9CA3AF')
          .margin({ right: 10 })

        Column() {
          Text(habit.title)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')

          Text(habit.target)
            .fontSize(14)
            .fontColor('#6B7280')
            .margin({ top: 4 })

          Text('日期：' + this.safeText(habit.date, '未设置') + '    时间：' + this.safeText(habit.startTime, '未设置') + ' - ' + this.safeText(habit.endTime, '未设置'))
            .fontSize(13)
            .fontColor(this.themeColor)
            .margin({ top: 6 })

          Text('已打卡：' + habit.days.toString() + ' / ' + habit.targetDays.toString() + ' 天    完成度：' + this.getHabitProgressText(habit))
            .fontSize(13)
            .fontColor(this.themeColor)
            .margin({ top: 6 })

          Row() {
            Row() {}
            .width(this.getHabitProgressWidth(habit))
            .height(8)
            .backgroundColor(this.themeColor)
            .borderRadius(4)
          }
          .width('100%')
          .height(8)
          .backgroundColor('#E5E7EB')
          .borderRadius(4)
          .margin({ top: 8 })

          Text('创建：' + habit.createDate + '    ' + (this.isCheckedToday(habit) ? '今日状态：已打卡' : '今日状态：未打卡'))
            .fontSize(12)
            .fontColor(this.isCheckedToday(habit) ? '#22C55E' : '#EF4444')
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .margin({ bottom: 12 })

      Row() {
        Button(this.isCheckedToday(habit) ? '取消今日打卡' : '今日打卡')
          .layoutWeight(1)
          .height(38)
          .fontSize(14)
          .backgroundColor(this.isCheckedToday(habit) ? '#9CA3AF' : '#22C55E')
          .borderRadius(12)
          .margin({ right: 8 })
          .onClick(() => {
            this.toggleHabit(habit.id)
          })

        Button('删除')
          .layoutWeight(1)
          .height(38)
          .fontSize(14)
          .backgroundColor('#EF4444')
          .borderRadius(12)
          .margin({ left: 8 })
          .onClick(() => {
            this.deleteHabit(habit.id)
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.isCheckedToday(habit) ? '#F0FDF4' : '#F9FAFB')
    .borderRadius(12)
    .margin({ bottom: 10 })
  }

  async initPreferencesAndLoad(): Promise<void> {
    await this.initPreferences()
    await this.loadHabits()
  }

  async initPreferences(): Promise<void> {
    if (this.dataPreferences !== null) {
      return
    }

    this.dataPreferences = await preferences.getPreferences(this.context, {
      name: this.STORE_NAME
    })
  }

  async loadHabits(): Promise<void> {
    if (this.dataPreferences === null) {
      return
    }

    let habitsValue = await this.dataPreferences.get(this.HABITS_KEY, '')
    if (typeof habitsValue === 'string' && habitsValue.length > 0) {
      try {
        let parsedHabits = JSON.parse(habitsValue) as HabitData[]
        this.habits = this.normalizeHabits(parsedHabits)
      } catch (err) {
        console.error('读取习惯失败')
      }
    }

    let nextIdValue = await this.dataPreferences.get(this.HABIT_NEXT_ID_KEY, 4)
    if (typeof nextIdValue === 'number') {
      this.habitNextId = nextIdValue
    }
  }

  normalizeHabits(list: HabitData[]): HabitData[] {
    let result: HabitData[] = []

    list.forEach((item: HabitData) => {
      let finalTargetDays = 30
      if (typeof item.targetDays === 'number' && item.targetDays > 0) {
        finalTargetDays = item.targetDays
      }

      let finalCheckedDates: string[] = []
      if (item.checkedDates !== undefined && item.checkedDates !== null) {
        item.checkedDates.forEach((dateText: string) => {
          let normalized = this.normalizeDateInput(dateText)
          if (finalCheckedDates.indexOf(normalized) < 0) {
            finalCheckedDates.push(normalized)
          }
        })
      }

      if (item.checkedDate !== undefined && item.checkedDate !== null && item.checkedDate.length > 0) {
        let normalizedCheckedDate = this.normalizeDateInput(item.checkedDate)
        if (finalCheckedDates.indexOf(normalizedCheckedDate) < 0) {
          finalCheckedDates.push(normalizedCheckedDate)
        }
      }

      let finalDays = item.days
      if (finalCheckedDates.length > finalDays) {
        finalDays = finalCheckedDates.length
      }

      result.push({
        id: item.id,
        title: item.title,
        target: this.safeText(item.target, '每日坚持完成'),
        days: finalDays,
        targetDays: finalTargetDays,
        date: this.normalizeDateInput(this.safeText(item.date, this.getToday())),
        startTime: this.safeText(item.startTime, '未设置'),
        endTime: this.safeText(item.endTime, '未设置'),
        checkedDate: this.safeText(item.checkedDate, ''),
        checkedDates: finalCheckedDates,
        createDate: this.safeText(item.createDate, this.getToday())
      })
    })

    return result
  }

  async saveHabits(): Promise<void> {
    if (this.dataPreferences === null) {
      await this.initPreferences()
    }

    if (this.dataPreferences === null) {
      return
    }

    await this.dataPreferences.put(this.HABITS_KEY, JSON.stringify(this.habits))
    await this.dataPreferences.put(this.HABIT_NEXT_ID_KEY, this.habitNextId)
    await this.dataPreferences.flush()
  }

  getFilteredHabits(): HabitData[] {
    if (this.habitSearchText.trim().length === 0) {
      return this.habits
    }

    let keyword = this.habitSearchText.trim().toLowerCase()

    return this.habits.filter((item: HabitData) => {
      return item.title.toLowerCase().includes(keyword)
        || item.target.toLowerCase().includes(keyword)
        || item.date.toLowerCase().includes(keyword)
        || item.startTime.toLowerCase().includes(keyword)
        || item.endTime.toLowerCase().includes(keyword)
    })
  }

  addHabit(): void {
    if (this.habitTitle.trim().length === 0) {
      return
    }

    let targetDays = this.parseTargetDays(this.habitTargetDaysText)

    let newHabit: HabitData = {
      id: this.habitNextId,
      title: this.habitTitle,
      target: this.habitTarget.trim().length === 0 ? '每日坚持完成' : this.habitTarget,
      days: 0,
      targetDays: targetDays,
      date: this.normalizeDateInput(this.habitDate),
      startTime: this.habitStartTime.trim().length === 0 ? '未设置' : this.habitStartTime,
      endTime: this.habitEndTime.trim().length === 0 ? '未设置' : this.habitEndTime,
      checkedDate: '',
      checkedDates: [],
      createDate: this.getToday()
    }

    this.habits = [newHabit, ...this.habits]
    this.habitNextId = this.habitNextId + 1

    this.habitTitle = ''
    this.habitTarget = ''
    this.habitTargetDaysText = ''
    this.habitDate = this.getToday()
    this.habitStartTime = ''
    this.habitEndTime = ''
    this.showAddPanel = false

    this.saveHabits().then(() => {
      console.info('习惯保存成功')
    }).catch(() => {
      console.error('习惯保存失败')
    })
  }

  parseTargetDays(value: string): number {
    let parsed = Number(value)
    if (isNaN(parsed) || parsed <= 0) {
      return 30
    }

    return Math.floor(parsed)
  }

  toggleHabit(id: number): void {
    let today = this.getToday()
    let newHabits: HabitData[] = []

    this.habits.forEach((item: HabitData) => {
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

        newHabits.push({
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
        newHabits.push({
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

    this.habits = newHabits

    this.saveHabits().then(() => {
      console.info('习惯打卡状态已保存')
    }).catch(() => {
      console.error('习惯打卡状态保存失败')
    })
  }

  deleteHabit(id: number): void {
    this.habits = this.habits.filter((item: HabitData) => {
      return item.id !== id
    })

    this.saveHabits().then(() => {
      console.info('习惯删除后已保存')
    }).catch(() => {
      console.error('习惯删除后保存失败')
    })
  }

  isCheckedToday(habit: HabitData): boolean {
    if (habit.checkedDates !== undefined && habit.checkedDates !== null) {
      return habit.checkedDates.indexOf(this.getToday()) >= 0
    }
    return habit.checkedDate === this.getToday()
  }

  getTodayCheckedCount(): number {
    return this.habits.filter((item: HabitData) => {
      return this.isCheckedToday(item)
    }).length
  }

  getTodayRateText(): string {
    if (this.habits.length === 0) {
      return '0%'
    }

    let rate = Math.round(this.getTodayCheckedCount() * 100 / this.habits.length)
    return rate.toString() + '%'
  }

  getHabitProgressValue(habit: HabitData): number {
    if (habit.targetDays <= 0) {
      return 0
    }

    let value = Math.round(habit.days * 100 / habit.targetDays)
    if (value > 100) {
      return 100
    }

    if (value < 0) {
      return 0
    }

    return value
  }

  getHabitProgressText(habit: HabitData): string {
    return this.getHabitProgressValue(habit).toString() + '%'
  }

  getHabitProgressWidth(habit: HabitData): string {
    return this.getHabitProgressValue(habit).toString() + '%'
  }

  normalizeDateInput(value: string): string {
    let raw = this.safeText(value, '').trim()

    if (raw.length === 0 || raw === '未设置') {
      return this.getToday()
    }

    if (raw === '今天') {
      return this.getToday()
    }

    if (raw === '明天') {
      return this.addDays(this.getToday(), 1)
    }

    raw = raw.replace('年', '-')
    raw = raw.replace('月', '-')
    raw = raw.replace('日', '')
    raw = raw.replace('号', '')
    raw = raw.replace('/', '-')
    raw = raw.replace('.', '-')

    let parts = raw.split('-')

    if (parts.length === 1) {
      let day = Number(parts[0])
      if (!isNaN(day) && day >= 1 && day <= 31) {
        let now = new Date()
        return this.formatDate(now.getFullYear(), now.getMonth() + 1, Math.floor(day))
      }
    }

    if (parts.length === 2) {
      let month = Number(parts[0])
      let day = Number(parts[1])
      if (!isNaN(month) && !isNaN(day)) {
        let now = new Date()
        return this.formatDate(now.getFullYear(), Math.floor(month), Math.floor(day))
      }
    }

    if (parts.length >= 3) {
      let year = Number(parts[0])
      let month = Number(parts[1])
      let day = Number(parts[2])
      if (!isNaN(year) && !isNaN(month) && !isNaN(day)) {
        return this.formatDate(Math.floor(year), Math.floor(month), Math.floor(day))
      }
    }

    return this.getToday()
  }

  addDays(dateText: string, count: number): string {
    let year = Number(dateText.substring(0, 4))
    let month = Number(dateText.substring(5, 7))
    let day = Number(dateText.substring(8, 10))
    let date = new Date(year, month - 1, day + count)
    return this.formatDate(date.getFullYear(), date.getMonth() + 1, date.getDate())
  }

  formatDate(year: number, month: number, day: number): string {
    let monthText = month < 10 ? '0' + month.toString() : month.toString()
    let dayText = day < 10 ? '0' + day.toString() : day.toString()
    return year.toString() + '-' + monthText + '-' + dayText
  }

  safeText(value: string, defaultValue: string): string {
    if (value === undefined || value === null || value.length === 0) {
      return defaultValue
    }
    return value
  }

  getToday(): string {
    let date = new Date()
    let year = date.getFullYear()
    let month = date.getMonth() + 1
    let day = date.getDate()

    let monthText = month < 10 ? '0' + month.toString() : month.toString()
    let dayText = day < 10 ? '0' + day.toString() : day.toString()

    return year.toString() + '-' + monthText + '-' + dayText
  }
}

@Component
struct MinePage {
  @Prop themeColor: string = '#4F7CFF'
  onThemeChange: (color: string) => void = (color: string) => {}

  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
  dataPreferences: preferences.Preferences | null = null

  readonly STORE_NAME: string = 'time_plan_store'

  readonly TASKS_KEY: string = 'plan_tasks'
  readonly TASK_NEXT_ID_KEY: string = 'plan_tasks_next_id'
  readonly NOTES_KEY: string = 'note_items'
  readonly NOTE_NEXT_ID_KEY: string = 'note_items_next_id'
  readonly HABITS_KEY: string = 'habit_items'
  readonly HABIT_NEXT_ID_KEY: string = 'habit_items_next_id'
  readonly THEME_KEY: string = 'app_theme_mode'

  @State taskCount: number = 0
  @State doneTaskCount: number = 0
  @State undoneTaskCount: number = 0
  @State noteCount: number = 0
  @State habitCount: number = 0
  @State todayCheckedHabitCount: number = 0
  @State themeMode: string = '默认蓝色'
  @State operationTip: string = '已进入进阶版：日历汇总 + 时间字段'
  refreshTimerId: number = -1

  aboutToAppear(): void {
    this.initPreferencesAndLoad().then(() => {
      this.startAutoRefresh()
    }).catch(() => {
      this.operationTip = '我的页数据加载失败'
    })
  }

  aboutToDisappear(): void {
    this.stopAutoRefresh()
  }

  build() {
    Scroll() {
      Column() {
        Text('我的')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2937')
          .margin({ top: 30, bottom: 20 })

        Column() {
          Text('鸿蒙全时计划 App')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')
            .margin({ bottom: 8 })

          Text('日历汇总计划、便签、打卡，支持本地存储和主题切换')
            .fontSize(15)
            .fontColor('#6B7280')
            .margin({ bottom: 10 })

          Text(this.operationTip)
            .fontSize(13)
            .fontColor(this.themeColor)
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .margin({ bottom: 16 })
        .alignItems(HorizontalAlign.Start)

        Column() {
          Text('详细统计')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')
            .margin({ bottom: 12 })

          SettingItem({ title: '待办任务', value: this.taskCount.toString() + ' 条' })
          SettingItem({ title: '已完成待办', value: this.doneTaskCount.toString() + ' 条' })
          SettingItem({ title: '未完成待办', value: this.undoneTaskCount.toString() + ' 条' })
          SettingItem({ title: '便签数量', value: this.noteCount.toString() + ' 条' })
          SettingItem({ title: '习惯数量', value: this.habitCount.toString() + ' 个' })
          SettingItem({ title: '今日已打卡', value: this.todayCheckedHabitCount.toString() + ' 个' })
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .margin({ bottom: 16 })

        Column() {
          Text('应用设置')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')
            .margin({ bottom: 12 })

          SettingItem({ title: '主题设置', value: this.themeMode })
          SettingItem({ title: '数据备份', value: 'Preferences 本地存储' })
          SettingItem({ title: '关于应用', value: 'V1.1.0' })

          Button('切换主题偏好')
            .width('100%')
            .height(44)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(this.themeColor)
            .borderRadius(12)
            .margin({ top: 8, bottom: 10 })
            .onClick(() => {
              this.switchTheme()
            })

          Button('清空全部本地数据')
            .width('100%')
            .height(44)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .backgroundColor('#EF4444')
            .borderRadius(12)
            .margin({ bottom: 4 })
            .onClick(() => {
              this.clearAllData()
            })
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .margin({ bottom: 30 })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F7FB')
  }

  startAutoRefresh(): void {
    if (this.refreshTimerId !== -1) {
      return
    }

    this.refreshTimerId = setInterval(() => {
      this.refreshStats()
    }, 1000)
  }

  stopAutoRefresh(): void {
    if (this.refreshTimerId !== -1) {
      clearInterval(this.refreshTimerId)
      this.refreshTimerId = -1
    }
  }

  async initPreferencesAndLoad(): Promise<void> {
    await this.initPreferences()
    await this.loadTheme()
    await this.refreshStats()
  }

  async initPreferences(): Promise<void> {
    if (this.dataPreferences !== null) {
      return
    }

    this.dataPreferences = await preferences.getPreferences(this.context, {
      name: this.STORE_NAME
    })
  }

  async loadTheme(): Promise<void> {
    if (this.dataPreferences === null) {
      return
    }

    let themeValue = await this.dataPreferences.get(this.THEME_KEY, '默认蓝色')
    if (typeof themeValue === 'string') {
      this.themeMode = themeValue
      this.onThemeChange(this.getThemeColorByMode(themeValue))
    }
  }

  async refreshStats(): Promise<void> {
    if (this.dataPreferences === null) {
      await this.initPreferences()
    }

    if (this.dataPreferences === null) {
      return
    }

    await this.loadTaskStats()
    await this.loadNoteStats()
    await this.loadHabitStats()
  }

  async loadTaskStats(): Promise<void> {
    if (this.dataPreferences === null) {
      return
    }

    let value = await this.dataPreferences.get(this.TASKS_KEY, '')
    if (typeof value === 'string' && value.length > 0) {
      try {
        let list = JSON.parse(value) as TodoTask[]
        this.taskCount = list.length
        this.doneTaskCount = list.filter((item: TodoTask) => {
          return item.done
        }).length
        this.undoneTaskCount = this.taskCount - this.doneTaskCount
      } catch (err) {
        this.taskCount = 0
        this.doneTaskCount = 0
        this.undoneTaskCount = 0
      }
    } else {
      this.taskCount = 0
      this.doneTaskCount = 0
      this.undoneTaskCount = 0
    }
  }

  async loadNoteStats(): Promise<void> {
    if (this.dataPreferences === null) {
      return
    }

    let value = await this.dataPreferences.get(this.NOTES_KEY, '')
    if (typeof value === 'string' && value.length > 0) {
      try {
        let list = JSON.parse(value) as NoteItem[]
        this.noteCount = list.length
      } catch (err) {
        this.noteCount = 0
      }
    } else {
      this.noteCount = 0
    }
  }

  async loadHabitStats(): Promise<void> {
    if (this.dataPreferences === null) {
      return
    }

    let value = await this.dataPreferences.get(this.HABITS_KEY, '')
    if (typeof value === 'string' && value.length > 0) {
      try {
        let list = JSON.parse(value) as HabitData[]
        this.habitCount = list.length
        this.todayCheckedHabitCount = list.filter((item: HabitData) => {
          return item.checkedDate === this.getToday()
        }).length
      } catch (err) {
        this.habitCount = 0
        this.todayCheckedHabitCount = 0
      }
    } else {
      this.habitCount = 0
      this.todayCheckedHabitCount = 0
    }
  }

  switchTheme(): void {
    if (this.themeMode === '默认蓝色') {
      this.themeMode = '清新绿色'
    } else if (this.themeMode === '清新绿色') {
      this.themeMode = '活力红色'
    } else {
      this.themeMode = '默认蓝色'
    }

    let color = this.getThemeColorByMode(this.themeMode)
    this.onThemeChange(color)

    this.saveTheme().then(() => {
      this.operationTip = '主题已切换为：' + this.themeMode
    }).catch(() => {
      this.operationTip = '主题偏好保存失败'
    })
  }

  getThemeColorByMode(mode: string): string {
    if (mode === '清新绿色') {
      return '#22C55E'
    }
    if (mode === '活力红色') {
      return '#EF4444'
    }
    return '#4F7CFF'
  }

  async saveTheme(): Promise<void> {
    if (this.dataPreferences === null) {
      await this.initPreferences()
    }

    if (this.dataPreferences === null) {
      return
    }

    await this.dataPreferences.put(this.THEME_KEY, this.themeMode)
    await this.dataPreferences.flush()
  }

  clearAllData(): void {
    this.clearAllDataAsync().then(() => {
      this.operationTip = '本地数据已清空'
    }).catch(() => {
      this.operationTip = '清空数据失败'
    })
  }

  async clearAllDataAsync(): Promise<void> {
    if (this.dataPreferences === null) {
      await this.initPreferences()
    }

    if (this.dataPreferences === null) {
      return
    }

    await this.dataPreferences.put(this.TASKS_KEY, JSON.stringify([]))
    await this.dataPreferences.put(this.TASK_NEXT_ID_KEY, 1)

    await this.dataPreferences.put(this.NOTES_KEY, JSON.stringify([]))
    await this.dataPreferences.put(this.NOTE_NEXT_ID_KEY, 1)

    await this.dataPreferences.put(this.HABITS_KEY, JSON.stringify([]))
    await this.dataPreferences.put(this.HABIT_NEXT_ID_KEY, 1)

    await this.dataPreferences.flush()

    this.taskCount = 0
    this.doneTaskCount = 0
    this.undoneTaskCount = 0
    this.noteCount = 0
    this.habitCount = 0
    this.todayCheckedHabitCount = 0
  }

  getToday(): string {
    let date = new Date()
    let year = date.getFullYear()
    let month = date.getMonth() + 1
    let day = date.getDate()

    let monthText = month < 10 ? '0' + month.toString() : month.toString()
    let dayText = day < 10 ? '0' + day.toString() : day.toString()

    return year.toString() + '-' + monthText + '-' + dayText
  }
}

@Component
struct StatBox {
  @Prop themeColor: string = '#4F7CFF'
  @Prop title: string = ''
  @Prop value: string = ''

  build() {
    Column() {
      Text(this.value)
        .fontSize(23)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColor)

      Text(this.title)
        .fontSize(13)
        .fontColor('#6B7280')
        .margin({ top: 4 })
    }
    .width('30%')
    .height(72)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F3F6FF')
    .borderRadius(14)
  }
}

@Component
struct SettingItem {
  @Prop title: string = ''
  @Prop value: string = ''

  build() {
    Row() {
      Text(this.title)
        .fontSize(16)
        .fontColor('#111827')

      Blank()

      Text(this.value)
        .fontSize(14)
        .fontColor('#6B7280')

      Text(' >')
        .fontSize(14)
        .fontColor('#9CA3AF')
    }
    .width('100%')
    .height(54)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .margin({ bottom: 10 })
  }
}
