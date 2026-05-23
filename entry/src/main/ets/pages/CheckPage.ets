//本文件不再使用

import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { HabitData } from '../model/AppModels'
import { StatBox } from '../components/StatBox'
import { safeText, getToday, normalizeDateInput } from '../utils/DateUtil'
import { STORE_NAME as TIME_PLAN_STORE_NAME, HABITS_KEY as PLAN_HABITS_KEY, HABIT_NEXT_ID_KEY as PLAN_HABIT_NEXT_ID_KEY } from '../utils/StoreConstants'
import { getTimePlanPreferences } from '../utils/PreferenceUtil'
import { AppColors } from '../utils/AppColors'

@Component
export struct CheckPage {
  @Prop themeColor: string = AppColors.BLUE

  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
  dataPreferences: preferences.Preferences | null = null

  readonly STORE_NAME: string = TIME_PLAN_STORE_NAME
  readonly HABITS_KEY: string = PLAN_HABITS_KEY
  readonly HABIT_NEXT_ID_KEY: string = PLAN_HABIT_NEXT_ID_KEY

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
          .fontColor(AppColors.GRAY_800)
          .margin({ top: 30, bottom: 8 })

        Text('建立习惯时填写日期、开始时间和结束时间')
          .fontSize(15)
          .fontColor(AppColors.GRAY_500)
          .margin({ bottom: 20 })

        TextInput({ text: this.habitSearchText, placeholder: '搜索习惯名称或目标...' })
          .width('100%')
          .height(44)
          .backgroundColor(AppColors.WHITE)
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
            .fontColor(AppColors.GRAY_900)
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
        .backgroundColor(AppColors.WHITE)
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
              this.habitDate = getToday()
            }
          })

        if (this.showAddPanel) {
          Column() {
            Text('新增习惯')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.GRAY_900)
              .margin({ bottom: 12 })

            TextInput({ text: this.habitTitle, placeholder: '请输入习惯名称，例如：背单词' })
              .width('100%')
              .height(44)
              .backgroundColor(AppColors.GRAY_50)
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.habitTitle = value
              })

            TextInput({ text: this.habitTarget, placeholder: '请输入目标，例如：每天 20 个单词' })
              .width('100%')
              .height(44)
              .backgroundColor(AppColors.GRAY_50)
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.habitTarget = value
              })

            TextInput({ text: this.habitTargetDaysText, placeholder: '请输入计划打卡天数，例如：30' })
              .width('100%')
              .height(44)
              .backgroundColor(AppColors.GRAY_50)
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.habitTargetDaysText = value
              })

            TextInput({ text: this.habitDate, placeholder: '请输入日期，例如：2026-05-17 或 19' })
              .width('100%')
              .height(44)
              .backgroundColor(AppColors.GRAY_50)
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
                .backgroundColor(AppColors.GRAY_50)
                .borderRadius(12)
                .padding({ left: 12, right: 12 })
                .margin({ right: 6 })
                .onChange((value: string) => {
                  this.habitStartTime = value
                })

              TextInput({ text: this.habitEndTime, placeholder: '结束 10:00' })
                .layoutWeight(1)
                .height(44)
                .backgroundColor(AppColors.GRAY_50)
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
              .backgroundColor(AppColors.GREEN)
              .borderRadius(12)
              .onClick(() => {
                this.addHabit()
              })
          }
          .width('100%')
          .padding(18)
          .backgroundColor(AppColors.WHITE)
          .borderRadius(18)
          .margin({ bottom: 18 })
        }

        Column() {
          Text('习惯列表')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ bottom: 12 })

          if (this.getFilteredHabits().length === 0) {
            Column() {
              Text('暂无匹配习惯')
                .fontSize(16)
                .fontColor(AppColors.GRAY_400)
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
  HabitCard(habit: HabitData) {
    Column() {
      Row() {
        Text(this.isCheckedToday(habit) ? '✓' : '○')
          .fontSize(24)
          .fontColor(this.isCheckedToday(habit) ? AppColors.GREEN : AppColors.GRAY_400)
          .margin({ right: 10 })

        Column() {
          Text(habit.title)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)

          Text(habit.target)
            .fontSize(14)
            .fontColor(AppColors.GRAY_500)
            .margin({ top: 4 })

          Text('日期：' + safeText(habit.date, '未设置') + '    时间：' + safeText(habit.startTime, '未设置') + ' - ' + safeText(habit.endTime, '未设置'))
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
          .backgroundColor(AppColors.GRAY_200)
          .borderRadius(4)
          .margin({ top: 8 })

          Text('创建：' + habit.createDate + '    ' + (this.isCheckedToday(habit) ? '今日状态：已打卡' : '今日状态：未打卡'))
            .fontSize(12)
            .fontColor(this.isCheckedToday(habit) ? AppColors.GREEN : AppColors.RED)
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
          .backgroundColor(this.isCheckedToday(habit) ? AppColors.GRAY_400 : AppColors.GREEN)
          .borderRadius(12)
          .margin({ right: 8 })
          .onClick(() => {
            this.toggleHabit(habit.id)
          })

        Button('删除')
          .layoutWeight(1)
          .height(38)
          .fontSize(14)
          .backgroundColor(AppColors.RED)
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
    .backgroundColor(this.isCheckedToday(habit) ? AppColors.GREEN_50 : AppColors.GRAY_50)
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

    this.dataPreferences = await getTimePlanPreferences(this.context)
  }

  async loadHabits(): Promise<void> {
    this.dataPreferences = await getTimePlanPreferences(this.context)

    if (this.dataPreferences === null) {
      this.habits = []
      this.habitNextId = 1
      return
    }

    let loadedHabits: HabitData[] = []
    let habitsValue = await this.dataPreferences.get(this.HABITS_KEY, '')
    if (typeof habitsValue === 'string' && habitsValue.length > 0) {
      try {
        let parsedHabits = JSON.parse(habitsValue) as HabitData[]
        loadedHabits = this.normalizeHabits(parsedHabits)
      } catch (err) {
        console.error('读取习惯失败')
      }
    }

    this.habits = loadedHabits

    let nextIdValue = await this.dataPreferences.get(this.HABIT_NEXT_ID_KEY, 1)
    if (typeof nextIdValue === 'number') {
      this.habitNextId = nextIdValue
    } else {
      this.habitNextId = 1
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
          let normalized = normalizeDateInput(dateText)
          if (finalCheckedDates.indexOf(normalized) < 0) {
            finalCheckedDates.push(normalized)
          }
        })
      }

      if (item.checkedDate !== undefined && item.checkedDate !== null && item.checkedDate.length > 0) {
        let normalizedCheckedDate = normalizeDateInput(item.checkedDate)
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
        target: safeText(item.target, '每日坚持完成'),
        days: finalDays,
        targetDays: finalTargetDays,
        date: normalizeDateInput(safeText(item.date, getToday())),
        startTime: safeText(item.startTime, '未设置'),
        endTime: safeText(item.endTime, '未设置'),
        checkedDate: safeText(item.checkedDate, ''),
        checkedDates: finalCheckedDates,
        createDate: safeText(item.createDate, getToday())
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
      date: normalizeDateInput(this.habitDate),
      startTime: this.habitStartTime.trim().length === 0 ? '未设置' : this.habitStartTime,
      endTime: this.habitEndTime.trim().length === 0 ? '未设置' : this.habitEndTime,
      checkedDate: '',
      checkedDates: [],
      createDate: getToday()
    }

    this.habits = [newHabit, ...this.habits]
    this.habitNextId = this.habitNextId + 1

    this.habitTitle = ''
    this.habitTarget = ''
    this.habitTargetDaysText = ''
    this.habitDate = getToday()
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
    let today = getToday()
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
      return habit.checkedDates.indexOf(getToday()) >= 0
    }
    return habit.checkedDate === getToday()
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

}
