import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { SettingItem } from '../components/SettingItem'
import { PrivacyPolicyPage } from './PrivacyPolicyPage'
import { UserAgreementPage } from './UserAgreementPage'
import { AboutAppPage } from './AboutAppPage'
import { FeatureIntroPage } from './FeatureIntroPage'
import {
  STORE_NAME as TIME_PLAN_STORE_NAME,
  TASKS_KEY as PLAN_TASKS_KEY,
  TASK_NEXT_ID_KEY as PLAN_TASK_NEXT_ID_KEY,
  NOTES_KEY as PLAN_NOTES_KEY,
  NOTE_NEXT_ID_KEY as PLAN_NOTE_NEXT_ID_KEY,
  HABITS_KEY as PLAN_HABITS_KEY,
  HABIT_NEXT_ID_KEY as PLAN_HABIT_NEXT_ID_KEY,
  FOCUS_RECORDS_KEY as PLAN_FOCUS_RECORDS_KEY,
  FOCUS_NEXT_ID_KEY as PLAN_FOCUS_NEXT_ID_KEY,
  THEME_KEY as PLAN_THEME_KEY
} from '../utils/StoreConstants'
import { getTimePlanPreferences } from '../utils/PreferenceUtil'
import { AppColors } from '../utils/AppColors'

@Component
export struct MinePage {
  @Prop themeColor: string = AppColors.BLUE
  onThemeChange: (color: string) => void = (color: string) => {}
  onDataCleared: () => void = () => {}

  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
  dataPreferences: preferences.Preferences | null = null

  readonly STORE_NAME: string = TIME_PLAN_STORE_NAME

  readonly TASKS_KEY: string = PLAN_TASKS_KEY
  readonly TASK_NEXT_ID_KEY: string = PLAN_TASK_NEXT_ID_KEY

  readonly NOTES_KEY: string = PLAN_NOTES_KEY
  readonly NOTE_NEXT_ID_KEY: string = PLAN_NOTE_NEXT_ID_KEY

  readonly HABITS_KEY: string = PLAN_HABITS_KEY
  readonly HABIT_NEXT_ID_KEY: string = PLAN_HABIT_NEXT_ID_KEY

  readonly FOCUS_RECORDS_KEY: string = PLAN_FOCUS_RECORDS_KEY
  readonly FOCUS_NEXT_ID_KEY: string = PLAN_FOCUS_NEXT_ID_KEY

  readonly THEME_KEY: string = PLAN_THEME_KEY

  @State themeMode: string = '默认蓝色'
  @State operationTip: string = '已新增隐私政策、用户协议和关于应用页面'
  @State currentInfoPage: string = 'main'
  @State currentFeatureTitle: string = ''
  @State currentFeatureContent: string = ''
  @State showClearConfirm: boolean = false

  aboutToAppear(): void {
    this.initPreferencesAndLoad().then(() => {
      console.info('我的页数据加载完成')
    }).catch(() => {
      this.operationTip = '我的页数据加载失败'
    })
  }

  build() {
    Stack() {
      this.MainContent()

      if (this.currentInfoPage === 'privacy') {
        PrivacyPolicyPage({
          themeColor: this.themeColor,
          onBack: () => {
            this.currentInfoPage = 'main'
          }
        })
      } else if (this.currentInfoPage === 'agreement') {
        UserAgreementPage({
          themeColor: this.themeColor,
          onBack: () => {
            this.currentInfoPage = 'main'
          }
        })
      } else if (this.currentInfoPage === 'about') {
        AboutAppPage({
          themeColor: this.themeColor,
          onBack: () => {
            this.currentInfoPage = 'main'
          }
        })
      } else if (this.currentInfoPage === 'feature') {
        FeatureIntroPage({
          themeColor: this.themeColor,
          title: this.currentFeatureTitle,
          description: this.currentFeatureContent,
          onBack: () => {
            this.currentInfoPage = 'main'
          }
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  MainContent() {
    Stack() {
      Scroll() {
      Column() {
        Text('我的')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.GRAY_800)
          .margin({ top: 30, bottom: 20 })

        Column() {
          Text('鸿蒙全时计划 App')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ bottom: 8 })

          Text('日历汇总计划、便签、打卡，支持专注记录、统计分析和主题切换')
            .fontSize(15)
            .fontColor(AppColors.GRAY_500)
            .margin({ bottom: 10 })

          Text(this.operationTip)
            .fontSize(13)
            .fontColor(this.themeColor)
        }
        .width('100%')
        .padding(20)
        .backgroundColor(AppColors.CARD_BG)
        .borderRadius(18)
        .margin({ bottom: 16 })
        .alignItems(HorizontalAlign.Start)

        Column() {
          Text('功能说明')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ bottom: 12 })

          this.FeatureActionItem(
            '日历安排',
            '查看按月安排说明',
            '在日历中按月查看计划、便签、打卡和专注记录，快速掌握每日安排。'
          )
          this.FeatureActionItem(
            '计划管理',
            '查看待办管理说明',
            '支持新增待办事项，设置日期时间并标记完成，帮助整理学习和生活任务。'
          )
          this.FeatureActionItem(
            '专注模式',
            '查看专注计时说明',
            '提供专注计时和历史记录，便于统计学习时长，培养稳定的专注习惯。'
          )
          this.FeatureActionItem(
            '统计分析',
            '查看统计汇总说明',
            '汇总计划完成、打卡和专注数据，以图文方式展示近期执行情况与变化趋势。'
          )
          this.FeatureActionItem(
            '本地存储',
            '查看数据保存说明',
            '所有计划、便签、习惯和专注记录优先保存在本机，便于离线使用。'
          )
        }
        .width('100%')
        .padding(18)
        .backgroundColor(AppColors.CARD_BG)
        .borderRadius(18)
        .margin({ bottom: 16 })

        Column() {
          Text('协议与说明')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ bottom: 12 })

          this.ActionItem('隐私政策', '查看数据与权限说明', 'privacy')
          this.ActionItem('用户协议', '查看应用使用规则', 'agreement')
          this.ActionItem('关于应用', '版本、功能与开发说明', 'about')
        }
        .width('100%')
        .padding(18)
        .backgroundColor(AppColors.CARD_BG)
        .borderRadius(18)
        .margin({ bottom: 16 })

        Column() {
          Text('应用设置')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ bottom: 12 })

          SettingItem({ title: '数据备份', value: 'Preferences 本地存储' })

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
            .backgroundColor(AppColors.RED)
            .borderRadius(12)
            .margin({ bottom: 10 })
            .onClick(() => {
              this.showClearConfirm = true
              this.operationTip = '请确认是否清空全部本地数据'
            })

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

      if (this.showClearConfirm) {
        Column() {
          Blank()

          this.ClearConfirmPanel()

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
  ClearConfirmPanel() {
    Column() {
      Text('确认清空全部本地数据？')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.RED)
        .margin({ bottom: 8 })

      Text('该操作会删除计划、便签、习惯打卡和专注记录。清空后不可恢复，请谨慎操作。')
        .fontSize(14)
        .fontColor(AppColors.GRAY_500)
        .lineHeight(22)
        .margin({ bottom: 14 })

      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(40)
          .fontSize(15)
          .backgroundColor(AppColors.GRAY_400)
          .borderRadius(12)
          .margin({ right: 8 })
          .onClick(() => {
            this.showClearConfirm = false
            this.operationTip = '已取消清空操作'
          })

        Button('确认清空')
          .layoutWeight(1)
          .height(40)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(AppColors.RED)
          .borderRadius(12)
          .margin({ left: 8 })
          .onClick(() => {
            this.showClearConfirm = false
            this.clearAllData()
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor(AppColors.CARD_BG)
    .borderRadius(20)
    .shadow({ radius: 20, color: '#33000000', offsetX: 0, offsetY: 8 })
    .border({ width: 1, color: '#FCA5A5' })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ActionItem(title: string, value: string, page: string) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor(AppColors.GRAY_900)

      Blank()

      Text(value)
        .fontSize(14)
        .fontColor(AppColors.GRAY_500)

      Text(' >')
        .fontSize(14)
        .fontColor(AppColors.GRAY_400)
    }
    .width('100%')
    .height(54)
    .padding({ left: 16, right: 16 })
    .backgroundColor(AppColors.CARD_BG)
    .borderRadius(14)
    .margin({ bottom: 10 })
    .onClick(() => {
      this.currentInfoPage = page
    })
  }

  @Builder
  FeatureActionItem(title: string, value: string, content: string) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor(AppColors.GRAY_900)

      Blank()

      Text(value)
        .fontSize(14)
        .fontColor(AppColors.GRAY_500)

      Text(' >')
        .fontSize(14)
        .fontColor(AppColors.GRAY_400)
    }
    .width('100%')
    .height(54)
    .padding({ left: 16, right: 16 })
    .backgroundColor(AppColors.CARD_BG)
    .borderRadius(14)
    .margin({ bottom: 10 })
    .onClick(() => {
      this.currentFeatureTitle = title
      this.currentFeatureContent = content
      this.currentInfoPage = 'feature'
    })
  }

  async initPreferencesAndLoad(): Promise<void> {
    await this.initPreferences()
    await this.loadTheme()
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
      return AppColors.GREEN
    }
    if (mode === '活力红色') {
      return AppColors.RED
    }
    return AppColors.BLUE
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
      this.onDataCleared()
      this.operationTip = '本地数据已清空，其他页面已同步为空'
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

    await this.dataPreferences.put(this.FOCUS_RECORDS_KEY, JSON.stringify([]))
    await this.dataPreferences.put(this.FOCUS_NEXT_ID_KEY, 1)

    await this.dataPreferences.flush()
  }
}
