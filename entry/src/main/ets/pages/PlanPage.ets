import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { TodoTask } from '../model/AppModels'
import { StatBox } from '../components/StatBox'
import { safeText, getToday, normalizeDateInput } from '../utils/DateUtil'
import { STORE_NAME as TIME_PLAN_STORE_NAME, TASKS_KEY as PLAN_TASKS_KEY, TASK_NEXT_ID_KEY as PLAN_TASK_NEXT_ID_KEY } from '../utils/StoreConstants'
import { getTimePlanPreferences } from '../utils/PreferenceUtil'
import { AppColors } from '../utils/AppColors'

interface CalendarSelectDay {
  date: string
  day: number
  isCurrentMonth: boolean
}

@Component
export struct PlanPage {
  @Prop themeColor: string = AppColors.BLUE

  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
  dataPreferences: preferences.Preferences | null = null

  readonly STORE_NAME: string = TIME_PLAN_STORE_NAME
  readonly TASKS_KEY: string = PLAN_TASKS_KEY
  readonly TASK_NEXT_ID_KEY: string = PLAN_TASK_NEXT_ID_KEY

  @State showAddPanel: boolean = false
  @State taskTitle: string = ''
  @State taskPriority: string = ''
  @State taskDate: string = ''
  @State taskStartTime: string = ''
  @State taskEndTime: string = ''
  @State taskSearchText: string = ''

  // 日期选择面板相关状态
  @State showTaskDatePicker: boolean = false
  @State pickerYear: number = 0
  @State pickerMonth: number = 0

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
    let now = new Date()
    this.pickerYear = now.getFullYear()
    this.pickerMonth = now.getMonth() + 1

    if (this.taskDate.trim().length === 0) {
      this.taskDate = getToday()
    }

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
          .fontColor(AppColors.GRAY_800)
          .margin({ top: 30, bottom: 8 })

        Text('建立待办时选择日期，并填写开始时间和结束时间')
          .fontSize(15)
          .fontColor(AppColors.GRAY_500)
          .margin({ bottom: 20 })

        TextInput({ text: this.taskSearchText, placeholder: '搜索待办任务...' })
          .width('100%')
          .height(44)
          .backgroundColor(AppColors.WHITE)
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
            .fontColor(AppColors.GRAY_900)
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
        .backgroundColor(AppColors.WHITE)
        .borderRadius(18)
        .margin({ bottom: 18 })

        Button(this.showAddPanel ? '取消' : '+ 新增待办')
          .width('100%')
          .height(48)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(this.themeColor)
          .borderRadius(16)
          .margin({ bottom: 14 })
          .onClick(() => {
            this.showAddPanel = !this.showAddPanel

            if (this.showAddPanel) {
              if (this.taskDate.trim().length === 0) {
                this.taskDate = getToday()
              }

              this.pickerYear = this.getYearFromDate(this.taskDate)
              this.pickerMonth = this.getMonthFromDate(this.taskDate)
            } else {
              this.showTaskDatePicker = false
            }
          })

        if (this.showAddPanel) {
          Column() {
            Text('新增待办任务')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.GRAY_900)
              .margin({ bottom: 12 })

            TextInput({ text: this.taskTitle, placeholder: '请输入任务名称，例如：完成课程报告' })
              .width('100%')
              .height(44)
              .backgroundColor(AppColors.GRAY_50)
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.taskTitle = value
              })

            TextInput({ text: this.taskPriority, placeholder: '请输入优先级：高 / 中 / 低' })
              .width('100%')
              .height(44)
              .backgroundColor(AppColors.GRAY_50)
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.taskPriority = value
              })

            Column() {
              Row() {
                Column() {
                  Text('任务日期')
                    .fontSize(13)
                    .fontColor(AppColors.GRAY_500)
                    .margin({ bottom: 4 })

                  Text(this.taskDate.length > 0 ? this.taskDate : '请选择日期')
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.taskDate.length > 0 ? AppColors.GRAY_900 : AppColors.GRAY_400)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Text(this.showTaskDatePicker ? '收起' : '选择')
                  .fontSize(14)
                  .fontColor(this.themeColor)
                  .fontWeight(FontWeight.Bold)
              }
              .width('100%')
              .height(56)
              .padding({ left: 12, right: 12 })
              .backgroundColor(AppColors.GRAY_50)
              .borderRadius(12)
              .onClick(() => {
                let baseDate = this.taskDate.length > 0 ? this.taskDate : getToday()
                this.pickerYear = this.getYearFromDate(baseDate)
                this.pickerMonth = this.getMonthFromDate(baseDate)

                animateTo({
                  duration: 220,
                  curve: Curve.EaseOut
                }, () => {
                  this.showTaskDatePicker = !this.showTaskDatePicker
                })
              })

              if (this.showTaskDatePicker) {
                this.TaskDatePickerPanel()
              }
            }
            .width('100%')
            .margin({ bottom: 10 })

            Row() {
              TextInput({ text: this.taskStartTime, placeholder: '开始 09:00' })
                .layoutWeight(1)
                .height(44)
                .backgroundColor(AppColors.GRAY_50)
                .borderRadius(12)
                .padding({ left: 12, right: 12 })
                .margin({ right: 6 })
                .onChange((value: string) => {
                  this.taskStartTime = value
                })

              TextInput({ text: this.taskEndTime, placeholder: '结束 10:00' })
                .layoutWeight(1)
                .height(44)
                .backgroundColor(AppColors.GRAY_50)
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
              .backgroundColor(AppColors.GREEN)
              .borderRadius(12)
              .onClick(() => {
                this.addTask()
              })
          }
          .width('100%')
          .padding(18)
          .backgroundColor(AppColors.WHITE)
          .borderRadius(18)
          .margin({ bottom: 18 })
        }

        Column() {
          Text('待办任务')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ bottom: 12 })

          if (this.getFilteredTasks().length === 0) {
            Column() {
              Text('暂无匹配任务')
                .fontSize(16)
                .fontColor(AppColors.GRAY_400)
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
  TaskDatePickerPanel() {
    Column() {
      Row() {
        Button('<')
          .width(42)
          .height(34)
          .fontSize(16)
          .backgroundColor(AppColors.GRAY_200)
          .fontColor(AppColors.GRAY_900)
          .borderRadius(10)
          .onClick(() => {
            this.goPreviousPickerMonth()
          })

        Blank()

        Text(this.pickerYear.toString() + '年' + this.pickerMonth.toString() + '月')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.GRAY_900)

        Blank()

        Button('>')
          .width(42)
          .height(34)
          .fontSize(16)
          .backgroundColor(AppColors.GRAY_200)
          .fontColor(AppColors.GRAY_900)
          .borderRadius(10)
          .onClick(() => {
            this.goNextPickerMonth()
          })
      }
      .width('100%')
      .margin({ bottom: 12 })

      Row() {
        ForEach(this.getWeekTitles(), (item: string) => {
          Text(item)
            .width('14.28%')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_500)
            .textAlign(TextAlign.Center)
        }, (item: string) => item)
      }
      .width('100%')
      .margin({ bottom: 8 })

      Grid() {
        ForEach(this.getPickerDays(), (day: CalendarSelectDay) => {
          GridItem() {
            Text(day.day.toString())
              .width('100%')
              .height(34)
              .fontSize(14)
              .fontWeight(day.date === this.taskDate ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.getPickerDayTextColor(day))
              .textAlign(TextAlign.Center)
              .backgroundColor(day.date === this.taskDate ? this.themeColor : AppColors.WHITE)
              .borderRadius(10)
              .border({
                width: day.date === getToday() && day.date !== this.taskDate ? 1 : 0,
                color: AppColors.BLUE,
                style: BorderStyle.Solid
              })
              .onClick(() => {
                this.selectTaskDate(day.date)
              })
          }
        }, (day: CalendarSelectDay) => day.date + '_' + day.isCurrentMonth.toString())
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
      .rowsGap(6)
      .columnsGap(6)
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .backgroundColor(AppColors.WHITE)
    .borderRadius(14)
    .margin({ top: 10 })
    .transition({
      type: TransitionType.All,
      opacity: 0,
      translate: { x: 0, y: -10 }
    })
  }

  @Builder
  TaskCard(task: TodoTask) {
    Column() {
      Row() {
        Text(task.done ? '✓' : '○')
          .fontSize(24)
          .fontColor(task.done ? AppColors.GREEN : AppColors.GRAY_400)
          .margin({ right: 10 })

        Column() {
          Text(task.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(task.done ? AppColors.GRAY_400 : AppColors.GRAY_900)

          Text('日期：' + safeText(task.date, '未设置') + '    时间：' + safeText(task.startTime, '未设置') + ' - ' + safeText(task.endTime, '未设置'))
            .fontSize(13)
            .fontColor(this.themeColor)
            .margin({ top: 4 })

          Text('优先级：' + task.priority + '    状态：' + (task.done ? '已完成' : '未完成'))
            .fontSize(12)
            .fontColor(AppColors.GRAY_500)
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
          .backgroundColor(task.done ? AppColors.GRAY_400 : AppColors.GREEN)
          .borderRadius(12)
          .margin({ right: 8 })
          .onClick(() => {
            this.toggleTask(task.id)
          })

        Button('删除')
          .layoutWeight(1)
          .height(38)
          .fontSize(14)
          .backgroundColor(AppColors.RED)
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
    .backgroundColor(task.done ? AppColors.GREEN_50 : AppColors.GRAY_50)
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

    this.dataPreferences = await getTimePlanPreferences(this.context)
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
        priority: safeText(item.priority, '中'),
        date: normalizeDateInput(safeText(item.date, getToday())),
        startTime: safeText(item.startTime, '未设置'),
        endTime: safeText(item.endTime, '未设置'),
        done: item.done,
        createDate: safeText(item.createDate, getToday())
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
      date: normalizeDateInput(this.taskDate),
      startTime: this.taskStartTime.trim().length === 0 ? '未设置' : this.taskStartTime,
      endTime: this.taskEndTime.trim().length === 0 ? '未设置' : this.taskEndTime,
      done: false,
      createDate: getToday()
    }

    this.tasks = [newTask, ...this.tasks]
    this.taskNextId = this.taskNextId + 1

    this.taskTitle = ''
    this.taskPriority = ''
    this.taskDate = getToday()
    this.taskStartTime = ''
    this.taskEndTime = ''
    this.showTaskDatePicker = false
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

  getWeekTitles(): string[] {
    return ['日', '一', '二', '三', '四', '五', '六']
  }

  getPickerDays(): CalendarSelectDay[] {
    let list: CalendarSelectDay[] = []

    let firstWeek = new Date(this.pickerYear, this.pickerMonth - 1, 1).getDay()
    let daysInMonth = new Date(this.pickerYear, this.pickerMonth, 0).getDate()

    let prevYear = this.pickerMonth === 1 ? this.pickerYear - 1 : this.pickerYear
    let prevMonth = this.pickerMonth === 1 ? 12 : this.pickerMonth - 1
    let nextYear = this.pickerMonth === 12 ? this.pickerYear + 1 : this.pickerYear
    let nextMonth = this.pickerMonth === 12 ? 1 : this.pickerMonth + 1
    let daysInPrevMonth = new Date(prevYear, prevMonth, 0).getDate()

    let realCellCount = firstWeek + daysInMonth
    let rowCount = Math.ceil(realCellCount / 7)

    if (rowCount < 5) {
      rowCount = 5
    }

    let totalCells = rowCount * 7

    for (let i = 0; i < totalCells; i++) {
      let finalYear = this.pickerYear
      let finalMonth = this.pickerMonth
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
        isCurrent = true
      }

      list.push({
        date: this.formatPickerDate(finalYear, finalMonth, finalDay),
        day: finalDay,
        isCurrentMonth: isCurrent
      })
    }

    return list
  }

  selectTaskDate(dateText: string): void {
    this.taskDate = dateText
    this.pickerYear = this.getYearFromDate(dateText)
    this.pickerMonth = this.getMonthFromDate(dateText)

    animateTo({
      duration: 180,
      curve: Curve.EaseOut
    }, () => {
      this.showTaskDatePicker = false
    })
  }

  goPreviousPickerMonth(): void {
    if (this.pickerMonth === 1) {
      this.pickerYear = this.pickerYear - 1
      this.pickerMonth = 12
    } else {
      this.pickerMonth = this.pickerMonth - 1
    }
  }

  goNextPickerMonth(): void {
    if (this.pickerMonth === 12) {
      this.pickerYear = this.pickerYear + 1
      this.pickerMonth = 1
    } else {
      this.pickerMonth = this.pickerMonth + 1
    }
  }

  getPickerDayTextColor(day: CalendarSelectDay): string {
    if (day.date === this.taskDate) {
      return AppColors.WHITE
    }

    if (!day.isCurrentMonth) {
      return AppColors.GRAY_400
    }

    if (day.date === getToday()) {
      return AppColors.BLUE
    }

    return AppColors.GRAY_900
  }

  getYearFromDate(dateText: string): number {
    if (dateText.length < 7) {
      let now = new Date()
      return now.getFullYear()
    }

    return Number(dateText.substring(0, 4))
  }

  getMonthFromDate(dateText: string): number {
    if (dateText.length < 7) {
      let now = new Date()
      return now.getMonth() + 1
    }

    return Number(dateText.substring(5, 7))
  }

  formatPickerDate(year: number, month: number, day: number): string {
    let monthText = month < 10 ? '0' + month.toString() : month.toString()
    let dayText = day < 10 ? '0' + day.toString() : day.toString()
    return year.toString() + '-' + monthText + '-' + dayText
  }
}