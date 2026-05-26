import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { TodoTask, NoteItem, HabitData, CalendarItem, CalendarDay } from '../model/AppModels'
import { StatBox } from '../components/StatBox'
import { EmptyState } from '../components/EmptyState'
import { STORE_NAME as TIME_PLAN_STORE_NAME, TASKS_KEY as PLAN_TASKS_KEY, NOTES_KEY as PLAN_NOTES_KEY, HABITS_KEY as PLAN_HABITS_KEY } from '../utils/StoreConstants'
import { getTimePlanPreferences } from '../utils/PreferenceUtil'
import { safeText, getToday, formatDate, formatMonth, normalizeDateInput, getWeekTitles, getYearFromDate, getMonthFromDate, dateInList, dateToDayNumber, dayNumberToDate, buildMonthDays, SimpleCalendarDay } from '../utils/DateUtil'
import { AppColors } from '../utils/AppColors'

@Component
export struct CalendarPage {
  @Prop themeColor: string = AppColors.BLUE
  @Prop @Watch('onDataRefreshVersionChange') dataRefreshVersion: number = 0

  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
  dataPreferences: preferences.Preferences | null = null

  readonly STORE_NAME: string = TIME_PLAN_STORE_NAME
  readonly TASKS_KEY: string = PLAN_TASKS_KEY
  readonly NOTES_KEY: string = PLAN_NOTES_KEY
  readonly HABITS_KEY: string = PLAN_HABITS_KEY

  @State currentYear: number = 2026
  @State currentMonth: number = 5
  @State selectedDate: string = ''
  @State allItems: CalendarItem[] = []
  @State calendarDays: CalendarDay[] = []
  @State operationTip: string = '点击日历中的日期，可查看当天详细安排'
  @State showMonthPicker: boolean = false
  @State showDayDetail: boolean = false
  @State pickerYear: number = 2026
  refreshTimerId: number = -1

  aboutToAppear(): void {
    let now = new Date()
    this.currentYear = now.getFullYear()
    this.currentMonth = now.getMonth() + 1
    this.selectedDate = getToday()

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

  onDataRefreshVersionChange(): void {
    this.loadCalendarItems().then(() => {
      this.updateCalendarDays()
      this.showDayDetail = false
      this.operationTip = '本地数据已清空，日历已同步为空'
    }).catch(() => {
      this.operationTip = '日历同步失败'
    })
  }

  build() {
    if (this.showDayDetail) {
      this.DayDetailPage()
    } else {
      this.CalendarMainPage()
    }
  }

  @Builder
  CalendarMainPage() {
    Scroll() {
      Column() {
        Text('日历安排')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.GRAY_800)
          .margin({ top: 30, bottom: 8 })

        Text('按月查看计划、便签、打卡中的全部安排')
          .fontSize(15)
          .fontColor(AppColors.GRAY_500)
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
              .fontColor(AppColors.GRAY_900)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(10)
              .backgroundColor(AppColors.SURFACE_ALT_BG)
              .onClick(() => {
                this.pickerYear = this.currentYear

                animateTo({
                  duration: 250,
                  curve: Curve.EaseOut
                }, () => {
                  this.showMonthPicker = !this.showMonthPicker
                })

                this.operationTip = !this.showMonthPicker ? '请选择年份和月份' : '点击日历中的日期，可查看当天详细安排'
              })

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

          if (this.showMonthPicker) {
            this.MonthPickerPanel()
          }

          Row() {
            ForEach(getWeekTitles(), (item: string) => {
              Text(item)
                .width('14.28%')
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.GRAY_500)
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
            }, (day: CalendarDay) => day.date + '_' + day.itemCount.toString() + '_' + day.doneCount.toString() + '_' + day.isSelected.toString() + '_' + day.isCurrentMonth.toString() )
          }
          .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
          .rowsGap(8)
          .columnsGap(6)
          .width('100%')
        }
        .width('100%')
        .padding(18)
        .backgroundColor(AppColors.CARD_BG)
        .borderRadius(18)
        .margin({ bottom: 18 })

        Column() {
          Text('当月概览')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
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
        .backgroundColor(AppColors.CARD_BG)
        .borderRadius(18)
        .margin({ bottom: 18 })

      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.PAGE_BG)
  }

  @Builder
  DayDetailPage() {
    Scroll() {
      Column() {
        Row() {
          Button('返回')
            .width(72)
            .height(36)
            .fontSize(14)
            .backgroundColor(this.themeColor)
            .borderRadius(12)
            .onClick(() => {
              this.showDayDetail = false
              this.operationTip = '点击日历中的日期，可查看当天详细安排'
            })

          Blank()

          Text('当天详情')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)

          Blank()

          Text('')
            .width(72)
        }
        .width('100%')
        .margin({ top: 30, bottom: 18 })

        Column() {
          Text(this.selectedDate)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ bottom: 8 })

          Text('这一天共有 ' + this.getSelectedDayItems().length.toString() + ' 项安排')
            .fontSize(15)
            .fontColor(this.themeColor)
        }
        .width('100%')
        .padding(20)
        .backgroundColor(AppColors.CARD_BG)
        .borderRadius(18)
        .margin({ bottom: 16 })
        .alignItems(HorizontalAlign.Start)

        Column() {
          Text('分类概览')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ bottom: 14 })

          Row() {
            StatBox({ themeColor: this.themeColor, title: '计划', value: this.getSelectedDayTypeCount('计划').toString() })
            StatBox({ themeColor: this.themeColor, title: '便签', value: this.getSelectedDayTypeCount('便签').toString() })
            StatBox({ themeColor: this.themeColor, title: '打卡', value: this.getSelectedDayTypeCount('打卡').toString() })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('100%')
        .padding(18)
        .backgroundColor(AppColors.CARD_BG)
        .borderRadius(18)
        .margin({ bottom: 16 })

        Column() {
          Text('详细安排')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ bottom: 12 })

          if (this.getSelectedDayItems().length === 0) {
            EmptyState({
              themeColor: this.themeColor,
              iconText: '计划',
              title: '这一天暂无计划',
              description: '可以到计划页新增待办、便签或打卡，填写日期和时间后会自动显示在这里。'
            })
          } else {
            ForEach(this.getSelectedDayItems(), (item: CalendarItem) => {
              this.CalendarCard(item)
            }, (item: CalendarItem) => item.type + '_' + item.id.toString() + '_' + item.date + '_' + item.startTime + '_' + item.endTime + '_' + item.done.toString() + '_' + item.description)
          }
        }
        .width('100%')
        .padding(18)
        .backgroundColor(AppColors.CARD_BG)
        .borderRadius(18)
        .margin({ bottom: 30 })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.PAGE_BG)
  }

  @Builder
  MonthPickerPanel() {
    Column() {
      Row() {
        Button('<')
          .width(42)
          .height(34)
          .fontSize(16)
          .backgroundColor(AppColors.BORDER_BG)
          .fontColor(AppColors.GRAY_900)
          .borderRadius(10)
          .onClick(() => {
            this.pickerYear = this.pickerYear - 1
          })

        Blank()

        Text(this.pickerYear.toString() + '年')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.GRAY_900)

        Blank()

        Button('>')
          .width(42)
          .height(34)
          .fontSize(16)
          .backgroundColor(AppColors.BORDER_BG)
          .fontColor(AppColors.GRAY_900)
          .borderRadius(10)
          .onClick(() => {
            this.pickerYear = this.pickerYear + 1
          })
      }
      .width('100%')
      .margin({ bottom: 12 })

      Grid() {
        ForEach(this.getMonthPickerList(), (month: number) => {
          GridItem() {
            Text(month.toString() + '月')
              .width('100%')
              .height(42)
              .fontSize(15)
              .fontWeight(this.pickerYear === this.currentYear && month === this.currentMonth ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.pickerYear === this.currentYear && month === this.currentMonth ? AppColors.WHITE : AppColors.GRAY_900)
              .textAlign(TextAlign.Center)
              .backgroundColor(this.pickerYear === this.currentYear && month === this.currentMonth ? this.themeColor : AppColors.SURFACE_BG)
              .borderRadius(12)
              .onClick(() => {
                this.selectMonth(this.pickerYear, month)
              })
          }
        }, (month: number) => month.toString())
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(10)
      .columnsGap(10)
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(AppColors.SURFACE_BG)
    .borderRadius(14)
    .margin({ bottom: 16 })
    .transition({
      type: TransitionType.All,
      opacity: 0,
      translate: { x: 0, y: -12 }
    })
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
          .fontColor(!day.isCurrentMonth ? AppColors.GRAY_400 : (day.isSelected ? AppColors.WHITE : this.themeColor))
          .margin({ top: 2 })
      } else {
        Text('')
          .fontSize(10)
          .margin({ top: 2 })
      }

      if (day.doneCount > 0) {
        Text(day.doneCount.toString() + '完成')
          .fontSize(9)
          .fontColor(!day.isCurrentMonth ? AppColors.GRAY_400 : (day.isSelected ? AppColors.WHITE : AppColors.GREEN))
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
    .backgroundColor(this.getDayBackgroundColor(day))
    .border({
      width: day.isToday && day.isCurrentMonth ? 2 : 0,
      color: day.isSelected ? AppColors.WHITE : AppColors.BLUE,
      style: BorderStyle.Solid
    })
    .borderRadius(12)
    .opacity(1)
    .onClick(() => {
      this.selectedDate = day.date
      this.currentYear = getYearFromDate(day.date)
      this.currentMonth = getMonthFromDate(day.date)
      this.updateCalendarDays()
      this.operationTip = '已选择：' + day.date
      this.showDayDetail = true
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
          .fontColor(AppColors.GRAY_500)
          .margin({ top: 4 })
      }
      .width(82)
      .alignItems(HorizontalAlign.Start)

      Column() {
        Row() {
          Text(item.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(item.done ? AppColors.GRAY_400 : AppColors.GRAY_900)
            .layoutWeight(1)

          if (item.type !== '便签') {
            Text(item.done ? '已完成' : '未完成')
              .fontSize(12)
              .fontColor(item.done ? AppColors.GREEN : AppColors.RED)
              .backgroundColor(item.done ? AppColors.GREEN_100 : AppColors.RED_100)
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .borderRadius(8)
          }
        }
        .width('100%')

        Text(item.description)
          .fontSize(13)
          .fontColor(AppColors.GRAY_500)
          .margin({ top: 6 })

        if (item.done && item.type === '计划') {
          Text('该计划已在计划页标记完成')
            .fontSize(12)
            .fontColor(AppColors.GREEN)
            .margin({ top: 6 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(item.done ? AppColors.GREEN_50 : AppColors.SURFACE_BG)
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

    this.dataPreferences = await getTimePlanPreferences(this.context)
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
    this.dataPreferences = await getTimePlanPreferences(this.context)

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
            date: normalizeDateInput(safeText(task.date, getToday()), this.currentYear, this.currentMonth),
            startTime: safeText(task.startTime, '未设置'),
            endTime: safeText(task.endTime, '未设置'),
            description: '优先级：' + safeText(task.priority, '中') + '，状态：' + (task.done ? '已完成' : '未完成'),
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
            date: normalizeDateInput(safeText(note.date, getToday()), this.currentYear, this.currentMonth),
            startTime: safeText(note.startTime, '未设置'),
            endTime: safeText(note.endTime, '未设置'),
            description: safeText(note.content, '暂无内容'),
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
          let startDate = normalizeDateInput(safeText(habit.date, getToday()), this.currentYear, this.currentMonth)
          let checkedDates = this.getHabitCheckedDates(habit)
          let scheduleDates = this.getHabitScheduleDates(startDate, habit.targetDays, checkedDates)

          scheduleDates.forEach((dateText: string) => {
            result.push({
              id: habit.id,
              type: '打卡',
              title: habit.title,
              date: dateText,
              startTime: safeText(habit.startTime, '未设置'),
              endTime: safeText(habit.endTime, '未设置'),
              description: '目标：' + safeText(habit.target, '每日坚持完成') + '，已打卡：' + habit.days.toString() + '/' + habit.targetDays.toString() + ' 天；漏打日期会自动顺延',
              done: dateInList(dateText, checkedDates)
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
    let baseDays = buildMonthDays(this.currentYear, this.currentMonth, 5)

    baseDays.forEach((day: SimpleCalendarDay) => {
      list.push({
        date: day.date,
        day: day.day,
        isCurrentMonth: day.isCurrentMonth,
        isToday: day.date === getToday(),
        isSelected: day.date === this.selectedDate,
        itemCount: this.getItemCountByDate(day.date),
        doneCount: this.getDoneCountByDate(day.date)
      })
    })

    this.calendarDays = list
  }

  goPreviousMonth(): void {
    if (this.currentMonth === 1) {
      this.currentYear = this.currentYear - 1
      this.currentMonth = 12
    } else {
      this.currentMonth = this.currentMonth - 1
    }

    this.selectedDate = formatDate(this.currentYear, this.currentMonth, 1)
    this.updateCalendarDays()
  }

  goNextMonth(): void {
    if (this.currentMonth === 12) {
      this.currentYear = this.currentYear + 1
      this.currentMonth = 1
    } else {
      this.currentMonth = this.currentMonth + 1
    }

    this.selectedDate = formatDate(this.currentYear, this.currentMonth, 1)
    this.updateCalendarDays()
  }

  getSelectedDayTypeCount(type: string): number {
    return this.getSelectedDayItems().filter((item: CalendarItem) => {
      return item.type === type
    }).length
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
    let monthText = formatMonth(this.currentYear, this.currentMonth)
    return this.allItems.filter((item: CalendarItem) => {
      return item.date.startsWith(monthText)
    }).length
  }

  getMonthTypeCount(type: string): number {
    let monthText = formatMonth(this.currentYear, this.currentMonth)
    return this.allItems.filter((item: CalendarItem) => {
      return item.date.startsWith(monthText) && item.type === type
    }).length
  }

  getDayTextColor(day: CalendarDay): ResourceColor {
    if (!day.isCurrentMonth) {
      return AppColors.GRAY_400
    }

    if (day.isSelected) {
      return AppColors.WHITE
    }

    if (day.isToday) {
      return AppColors.BLUE
    }

    return AppColors.GRAY_900
  }

  getDayBackgroundColor(day: CalendarDay): ResourceColor {
    if (!day.isCurrentMonth) {
      return AppColors.GRAY_100
    }

    if (day.isSelected) {
      return this.themeColor
    }

    if (day.itemCount > 0) {
      return AppColors.INDIGO_50
    }

    return AppColors.GRAY_50
  }

  getMonthPickerList(): number[] {
    return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
  }

  selectMonth(year: number, month: number): void {
    this.currentYear = year
    this.currentMonth = month
    this.selectedDate = formatDate(year, month, 1)
    this.showMonthPicker = false
    this.updateCalendarDays()
    this.operationTip = '已切换到：' + this.getMonthTitle()
  }

  getMonthTitle(): string {
    return this.currentYear.toString() + '年' + this.currentMonth.toString() + '月'
  }

  getHabitCheckedDates(habit: HabitData): string[] {
    let result: string[] = []

    if (habit.checkedDates !== undefined && habit.checkedDates !== null) {
      habit.checkedDates.forEach((dateText: string) => {
        let normalized = normalizeDateInput(dateText, this.currentYear, this.currentMonth)
        if (!dateInList(normalized, result)) {
          result.push(normalized)
        }
      })
    }

    if (habit.checkedDate !== undefined && habit.checkedDate !== null && habit.checkedDate.length > 0) {
      let normalizedCheckedDate = normalizeDateInput(habit.checkedDate, this.currentYear, this.currentMonth)
      if (!dateInList(normalizedCheckedDate, result)) {
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

    let endIndex = startIndex + finalTargetDays + missedBeforeToday - 1

    if (checkedDates.length >= finalTargetDays) {
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

}
