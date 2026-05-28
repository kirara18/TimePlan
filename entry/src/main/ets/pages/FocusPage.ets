import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { TodoTask, FocusRecord } from '../model/AppModels'
import { StatBox } from '../components/StatBox'
import { EmptyState } from '../components/EmptyState'
import { getToday, safeText } from '../utils/DateUtil'
import {
  TASKS_KEY as PLAN_TASKS_KEY,
  FOCUS_RECORDS_KEY as PLAN_FOCUS_RECORDS_KEY,
  FOCUS_NEXT_ID_KEY as PLAN_FOCUS_NEXT_ID_KEY
} from '../utils/StoreConstants'
import { getTimePlanPreferences } from '../utils/PreferenceUtil'
import { AppColors } from '../utils/AppColors'

@Component
export struct FocusPage {
  @Prop themeColor: string = AppColors.BLUE
  @Prop @Watch('onDataRefreshVersionChange') dataRefreshVersion: number = 0

  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
  dataPreferences: preferences.Preferences | null = null

  readonly TASKS_KEY: string = PLAN_TASKS_KEY
  readonly FOCUS_RECORDS_KEY: string = PLAN_FOCUS_RECORDS_KEY
  readonly FOCUS_NEXT_ID_KEY: string = PLAN_FOCUS_NEXT_ID_KEY

  @State tasks: TodoTask[] = []
  @State focusRecords: FocusRecord[] = []
  @State focusNextId: number = 1

  @State selectedTaskId: number = 0
  @State selectedTaskTitle: string = '自由专注'

  @State totalSeconds: number = 25 * 60
  @State remainSeconds: number = 25 * 60
  @State isRunning: boolean = false
  @State operationTip: string = ''

  @State customMinutesText: string = ''
  @State durationTip: string = '当前时长：25 分钟'

  timerId: number = -1
  dataSyncTimerId: number = -1
  focusStartTime: string = ''

  aboutToAppear(): void {
    this.initPreferencesAndLoad().then(() => {
      this.startDataAutoRefresh()
      console.info('专注页数据加载完成')
    }).catch(() => {
      this.operationTip = '专注页数据加载失败'
      console.error('专注页数据加载失败')
    })
  }

  aboutToDisappear(): void {
    this.stopTimerOnly()
    this.stopDataAutoRefresh()
  }

  onDataRefreshVersionChange(): void {
    this.stopTimerOnly()
    this.isRunning = false
    this.selectedTaskId = 0
    this.selectedTaskTitle = '自由专注'
    this.focusStartTime = ''
    this.remainSeconds = this.totalSeconds

    this.initPreferencesAndLoad().then(() => {
      this.operationTip = ''
    }).catch(() => {
      this.operationTip = '专注页同步失败'
    })
  }

  build() {
    Scroll() {
      Column() {
        Text('专注')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.GRAY_800)
          .margin({ top: 30, bottom: 8 })

        Text('可绑定待办进行番茄钟专注，也可直接开始自由倒计时')
          .fontSize(15)
          .fontColor(AppColors.GRAY_500)
          .margin({ bottom: 20 })

        Column() {
          Text('今日专注')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ bottom: 14 })

          Row() {
            StatBox({ themeColor: this.themeColor, title: '次数', value: this.getTodayFocusCount().toString() })
            StatBox({ themeColor: this.themeColor, title: '分钟', value: this.getTodayFocusMinutes().toString() })
            StatBox({ themeColor: this.themeColor, title: '待办', value: this.tasks.length.toString() })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('100%')
        .padding(18)
        .backgroundColor(AppColors.CARD_BG)
        .borderRadius(18)
        .margin({ bottom: 18 })

        Column() {
          Text(this.formatRemainTime())
            .fontSize(56)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ top: 10, bottom: 8 })

          if (this.operationTip.length > 0) {
            Text(this.operationTip)
              .fontSize(14)
              .fontColor(AppColors.RED)
              .margin({ bottom: 8 })
          }

          Text(this.durationTip)
            .fontSize(13)
            .fontColor(this.themeColor)
            .margin({ bottom: 18 })

          Row() {
            this.DurationButton('25分钟', 25)
            this.DurationButton('45分钟', 45)
            this.DurationButton('60分钟', 60)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ bottom: 12 })

          Row() {
            TextInput({ text: this.customMinutesText, placeholder: '自定义分钟数' })
              .layoutWeight(1)
              .height(42)
              .fontColor(AppColors.INPUT_TEXT)
              .placeholderColor(AppColors.INPUT_PLACEHOLDER)
              .fontSize(14)
              .backgroundColor(AppColors.INPUT_BG)
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ right: 8 })
              .onChange((value: string) => {
                this.customMinutesText = value
              })

            Button('设置')
              .width(86)
              .height(42)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .backgroundColor(this.themeColor)
              .borderRadius(12)
              .onClick(() => {
                this.setCustomDuration()
              })
          }
          .width('100%')
          .margin({ bottom: 18 })

          Row() {
            Button(this.isRunning ? '暂停' : '开始')
              .layoutWeight(1)
              .height(46)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .backgroundColor(this.isRunning ? AppColors.GRAY_400 : this.themeColor)
              .borderRadius(14)
              .margin({ right: 8 })
              .onClick(() => {
                if (this.isRunning) {
                  this.pauseFocus()
                } else {
                  this.startFocus()
                }
              })

            Button('重置')
              .layoutWeight(1)
              .height(46)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .backgroundColor(AppColors.RED)
              .borderRadius(14)
              .margin({ left: 8 })
              .onClick(() => {
                this.resetFocus()
              })
          }
          .width('100%')
        }
        .width('100%')
        .padding(18)
        .backgroundColor(AppColors.CARD_BG)
        .borderRadius(18)
        .margin({ bottom: 18 })

        Column() {
          Text('绑定计划')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ bottom: 12 })

          this.FreeFocusItem()

          if (this.tasks.length === 0) {
            EmptyState({
              themeColor: this.themeColor,
              iconText: '专',
              title: '暂无可绑定待办',
              description: '你仍然可以直接使用自由专注，也可以先到计划页创建待办。'
            })
          } else {
            ForEach(this.tasks, (task: TodoTask) => {
              this.TaskSelectItem(task)
            }, (task: TodoTask) => task.id.toString() + '_' + task.done.toString())
          }
        }
        .width('100%')
        .padding(18)
        .backgroundColor(AppColors.CARD_BG)
        .borderRadius(18)
        .margin({ bottom: 18 })

        Column() {
          Text('专注记录')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ bottom: 12 })

          if (this.getTodayRecords().length === 0) {
            EmptyState({
              themeColor: this.themeColor,
              iconText: '专注',
              title: '今天还没有专注记录',
              description: '完成一次专注后，记录会自动显示在这里。'
            })
          } else {
            ForEach(this.getTodayRecords(), (record: FocusRecord) => {
              this.FocusRecordItem(record)
            }, (record: FocusRecord) => record.id.toString())
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
  DurationButton(title: string, minutes: number) {
    Button(title)
      .width('31%')
      .height(40)
      .fontSize(14)
      .fontColor(this.totalSeconds === minutes * 60 ? AppColors.WHITE : AppColors.GRAY_900)
      .backgroundColor(this.totalSeconds === minutes * 60 ? this.themeColor : AppColors.SURFACE_ALT_BG)
      .borderRadius(12)
      .onClick(() => {
        if (!this.isRunning) {
          this.totalSeconds = minutes * 60
          this.remainSeconds = minutes * 60
          this.durationTip = '当前时长：' + minutes.toString() + ' 分钟'
          this.operationTip = ''
        }
      })
  }

  @Builder
  FreeFocusItem() {
    Row() {
      Text(this.selectedTaskId === 0 ? '●' : '○')
        .fontSize(22)
        .fontColor(this.selectedTaskId === 0 ? this.themeColor : AppColors.GRAY_400)
        .margin({ right: 10 })

      Column() {
        Text('自由专注')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.GRAY_900)

        Text('不绑定待办，直接开始一个倒计时')
          .fontSize(12)
          .fontColor(AppColors.GRAY_500)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('可直接开始')
        .fontSize(12)
        .fontColor(this.themeColor)
        .backgroundColor(AppColors.INDIGO_50)
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .borderRadius(8)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.selectedTaskId === 0 ? AppColors.INDIGO_50 : AppColors.SURFACE_BG)
    .borderRadius(12)
    .margin({ bottom: 10 })
    .onClick(() => {
      if (!this.isRunning) {
        this.selectedTaskId = 0
        this.selectedTaskTitle = '自由专注'
        this.operationTip = ''
      }
    })
  }

  @Builder
  TaskSelectItem(task: TodoTask) {
    Row() {
      Text(this.selectedTaskId === task.id ? '●' : '○')
        .fontSize(22)
        .fontColor(this.selectedTaskId === task.id ? this.themeColor : AppColors.GRAY_400)
        .margin({ right: 10 })

      Column() {
        Text(task.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(task.done ? AppColors.GRAY_400 : AppColors.GRAY_900)

        Text('日期：' + safeText(task.date, '未设置') + '    时间：' + safeText(task.startTime, '未设置') + ' - ' + safeText(task.endTime, '未设置'))
          .fontSize(12)
          .fontColor(AppColors.GRAY_500)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text(task.done ? '已完成' : '未完成')
        .fontSize(12)
        .fontColor(task.done ? AppColors.GREEN : AppColors.RED)
        .backgroundColor(task.done ? AppColors.GREEN_100 : AppColors.RED_100)
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .borderRadius(8)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.selectedTaskId === task.id ? AppColors.INDIGO_50 : AppColors.SURFACE_BG)
    .borderRadius(12)
    .margin({ bottom: 10 })
    .onClick(() => {
      if (!this.isRunning) {
        this.selectedTaskId = task.id
        this.selectedTaskTitle = task.title
        this.operationTip = ''
      }
    })
  }

  @Builder
  FocusRecordItem(record: FocusRecord) {
    Row() {
      Column() {
        Text(record.taskTitle)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.GRAY_900)

        Text(record.startTime + ' - ' + record.endTime)
          .fontSize(12)
          .fontColor(AppColors.GRAY_500)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text(record.durationMinutes.toString() + '分钟')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColor)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(AppColors.SURFACE_BG)
    .borderRadius(12)
    .margin({ bottom: 10 })
  }

  startDataAutoRefresh(): void {
    if (this.dataSyncTimerId !== -1) {
      return
    }

    this.dataSyncTimerId = setInterval(() => {
      if (!this.isRunning) {
        this.loadTasks().then(() => {
          // 计划页新增待办后，专注页绑定计划列表会自动刷新
        }).catch(() => {
          console.error('专注页自动同步待办失败')
        })

        this.loadFocusRecords().then(() => {
          // 专注记录自动刷新
        }).catch(() => {
          console.error('专注页自动同步记录失败')
        })
      }
    }, 800)
  }

  stopDataAutoRefresh(): void {
    if (this.dataSyncTimerId !== -1) {
      clearInterval(this.dataSyncTimerId)
      this.dataSyncTimerId = -1
    }
  }

  async initPreferencesAndLoad(): Promise<void> {
    await this.initPreferences()
    await this.loadTasks()
    await this.loadFocusRecords()
  }

  async initPreferences(): Promise<void> {
    if (this.dataPreferences !== null) {
      return
    }

    this.dataPreferences = await getTimePlanPreferences(this.context)
  }

  async loadTasks(): Promise<void> {
    this.dataPreferences = await getTimePlanPreferences(this.context)

    if (this.dataPreferences === null) {
      this.tasks = []
      return
    }

    let loadedTasks: TodoTask[] = []
    let tasksValue = await this.dataPreferences.get(this.TASKS_KEY, '')
    if (typeof tasksValue === 'string' && tasksValue.length > 0) {
      try {
        let parsedTasks = JSON.parse(tasksValue) as TodoTask[]
        parsedTasks.forEach((item: TodoTask) => {
          loadedTasks.push({
            id: item.id,
            title: safeText(item.title, '未命名待办'),
            priority: safeText(item.priority, '中'),
            date: safeText(item.date, getToday()),
            startTime: safeText(item.startTime, '未设置'),
            endTime: safeText(item.endTime, '未设置'),
            done: item.done === true,
            createDate: safeText(item.createDate, getToday())
          })
        })
      } catch (err) {
        console.error('专注页读取待办失败')
      }
    }

    this.tasks = loadedTasks
  }

  async loadFocusRecords(): Promise<void> {
    this.dataPreferences = await getTimePlanPreferences(this.context)

    if (this.dataPreferences === null) {
      this.focusRecords = []
      this.focusNextId = 1
      return
    }

    let loadedRecords: FocusRecord[] = []
    let recordsValue = await this.dataPreferences.get(this.FOCUS_RECORDS_KEY, '')
    if (typeof recordsValue === 'string' && recordsValue.length > 0) {
      try {
        loadedRecords = JSON.parse(recordsValue) as FocusRecord[]
      } catch (err) {
        console.error('专注记录读取失败')
      }
    }

    this.focusRecords = loadedRecords

    let nextIdValue = await this.dataPreferences.get(this.FOCUS_NEXT_ID_KEY, 1)
    if (typeof nextIdValue === 'number') {
      this.focusNextId = nextIdValue
    } else {
      this.focusNextId = 1
    }
  }

  async saveFocusRecords(): Promise<void> {
    if (this.dataPreferences === null) {
      await this.initPreferences()
    }

    if (this.dataPreferences === null) {
      return
    }

    await this.dataPreferences.put(this.FOCUS_RECORDS_KEY, JSON.stringify(this.focusRecords))
    await this.dataPreferences.put(this.FOCUS_NEXT_ID_KEY, this.focusNextId)
    await this.dataPreferences.flush()
  }

  setCustomDuration(): void {
    if (this.isRunning) {
      return
    }

    let minutes = Number(this.customMinutesText.trim())

    if (isNaN(minutes) || minutes <= 0) {
      this.operationTip = '请输入大于 0 的分钟数'
      return
    }

    let finalMinutes = Math.floor(minutes)

    this.totalSeconds = finalMinutes * 60
    this.remainSeconds = finalMinutes * 60
    this.durationTip = '当前时长：' + finalMinutes.toString() + ' 分钟'
    this.operationTip = ''
  }

  startFocus(): void {
    if (this.remainSeconds <= 0) {
      this.remainSeconds = this.totalSeconds
    }

    if (this.totalSeconds <= 0) {
      this.totalSeconds = 25 * 60
      this.remainSeconds = 25 * 60
      this.durationTip = '当前时长：25 分钟'
    }

    if (this.focusStartTime.length === 0) {
      this.focusStartTime = this.getCurrentTimeText()
    }

    this.isRunning = true
    this.operationTip = ''

    if (this.timerId !== -1) {
      return
    }

    this.timerId = setInterval(() => {
      if (this.remainSeconds > 0) {
        this.remainSeconds = this.remainSeconds - 1
      }

      if (this.remainSeconds <= 0) {
        this.finishFocus()
      }
    }, 1000)
  }

  pauseFocus(): void {
    this.stopTimerOnly()
    this.isRunning = false
    this.operationTip = ''
  }

  resetFocus(): void {
    this.stopTimerOnly()
    this.isRunning = false
    this.remainSeconds = this.totalSeconds
    this.focusStartTime = ''
    this.operationTip = ''
  }

  finishFocus(): void {
    this.stopTimerOnly()
    this.isRunning = false
    this.remainSeconds = this.totalSeconds

    let durationMinutes = Math.floor(this.totalSeconds / 60)
    let record: FocusRecord = {
      id: this.focusNextId,
      taskId: this.selectedTaskId,
      taskTitle: this.getCurrentFocusTitle(),
      durationMinutes: durationMinutes,
      date: getToday(),
      startTime: this.focusStartTime.length === 0 ? this.getCurrentTimeText() : this.focusStartTime,
      endTime: this.getCurrentTimeText(),
      createTime: new Date().getTime()
    }

    this.focusRecords = [record, ...this.focusRecords]
    this.focusNextId = this.focusNextId + 1
    this.focusStartTime = ''
    this.operationTip = ''

    this.saveFocusRecords().then(() => {
      console.info('专注记录保存成功')
    }).catch(() => {
      this.operationTip = '专注记录保存失败'
      console.error('专注记录保存失败')
    })
  }

  stopTimerOnly(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
      this.timerId = -1
    }
  }

  getCurrentFocusTitle(): string {
    if (this.selectedTaskId === 0 || this.selectedTaskTitle.length === 0 || this.selectedTaskTitle === '未选择待办') {
      return '自由专注'
    }

    return this.selectedTaskTitle
  }

  formatRemainTime(): string {
    let minute = Math.floor(this.remainSeconds / 60)
    let second = this.remainSeconds % 60
    let minuteText = minute < 10 ? '0' + minute.toString() : minute.toString()
    let secondText = second < 10 ? '0' + second.toString() : second.toString()
    return minuteText + ':' + secondText
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

  getCurrentTimeText(): string {
    let date = new Date()
    let hour = date.getHours()
    let minute = date.getMinutes()
    let hourText = hour < 10 ? '0' + hour.toString() : hour.toString()
    let minuteText = minute < 10 ? '0' + minute.toString() : minute.toString()
    return hourText + ':' + minuteText
  }
}
