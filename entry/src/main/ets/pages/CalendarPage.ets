import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { TodoTask, NoteItem, HabitData, CalendarItem, CalendarDay } from '../model/AppModels'
import { StatBox } from '../components/StatBox'

@Component
export struct CalendarPage {
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
