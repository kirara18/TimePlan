import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { TodoTask, NoteItem, HabitData } from '../model/AppModels'
import { SettingItem } from '../components/SettingItem'
import { getToday } from '../utils/DateUtil'
import { STORE_NAME as TIME_PLAN_STORE_NAME, TASKS_KEY as PLAN_TASKS_KEY, TASK_NEXT_ID_KEY as PLAN_TASK_NEXT_ID_KEY, NOTES_KEY as PLAN_NOTES_KEY, NOTE_NEXT_ID_KEY as PLAN_NOTE_NEXT_ID_KEY, HABITS_KEY as PLAN_HABITS_KEY, HABIT_NEXT_ID_KEY as PLAN_HABIT_NEXT_ID_KEY, THEME_KEY as PLAN_THEME_KEY } from '../utils/StoreConstants'
import { getTimePlanPreferences } from '../utils/PreferenceUtil'

@Component
export struct MinePage {
  @Prop themeColor: string = '#4F7CFF'
  onThemeChange: (color: string) => void = (color: string) => {}

  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
  dataPreferences: preferences.Preferences | null = null

  readonly STORE_NAME: string = TIME_PLAN_STORE_NAME

  readonly TASKS_KEY: string = PLAN_TASKS_KEY
  readonly TASK_NEXT_ID_KEY: string = PLAN_TASK_NEXT_ID_KEY
  readonly NOTES_KEY: string = PLAN_NOTES_KEY
  readonly NOTE_NEXT_ID_KEY: string = PLAN_NOTE_NEXT_ID_KEY
  readonly HABITS_KEY: string = PLAN_HABITS_KEY
  readonly HABIT_NEXT_ID_KEY: string = PLAN_HABIT_NEXT_ID_KEY
  readonly THEME_KEY: string = PLAN_THEME_KEY

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

    this.dataPreferences = await getTimePlanPreferences(this.context)
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
          return item.checkedDate === getToday()
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

}
