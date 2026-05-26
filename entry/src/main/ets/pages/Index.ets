import { CalendarPage } from './CalendarPage'
import { PlanPage } from './PlanPage'
import { FocusPage } from './FocusPage'
import { ReviewPage } from './ReviewPage'
import { MinePage } from './MinePage'
import { AppColors } from '../utils/AppColors'

@Entry
@Component
struct Index {
  @State currentIndex: number = 0
  @State themeColor: string = AppColors.BLUE
  @State showSplash: boolean = true
  @State dataRefreshVersion: number = 0

  aboutToAppear(): void {
    setTimeout(() => {
      this.showSplash = false
    }, 1200)
  }

  build() {
    if (this.showSplash) {
      SplashScreen({ themeColor: this.themeColor })
    } else {
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
      TabContent() {
        CalendarPage({
          themeColor: this.themeColor,
          dataRefreshVersion: this.dataRefreshVersion
        })
      }
      .tabBar('日历')

      TabContent() {
        PlanPage({
          themeColor: this.themeColor,
          dataRefreshVersion: this.dataRefreshVersion
        })
      }
      .tabBar('计划')

      TabContent() {
        FocusPage({
          themeColor: this.themeColor,
          dataRefreshVersion: this.dataRefreshVersion
        })
      }
      .tabBar('专注')

      TabContent() {
        ReviewPage({
          themeColor: this.themeColor,
          dataRefreshVersion: this.dataRefreshVersion
        })
      }
      .tabBar('统计')

      TabContent() {
        MinePage({
          themeColor: this.themeColor,
          onThemeChange: (color: string) => {
            this.themeColor = color
          },
          onDataCleared: () => {
            this.dataRefreshVersion = this.dataRefreshVersion + 1
          }
        })
      }
      .tabBar('我的')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.PAGE_BG)
      .onChange((index: number) => {
        this.currentIndex = index
      })
    }
  }
}

@Component
struct SplashScreen {
  @Prop themeColor: string = AppColors.BLUE

  build() {
    Column() {
      Blank()

      Column() {
        Text('全')
          .fontSize(46)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.WHITE)
      }
      .width(92)
      .height(92)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.themeColor)
      .borderRadius(28)
      .shadow({ radius: 24, color: '#33000000', offsetX: 0, offsetY: 10 })
      .margin({ bottom: 22 })

      Text('全时计划')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.GRAY_900)
        .margin({ bottom: 8 })

      Text('日历 · 计划 · 专注 · 统计')
        .fontSize(15)
        .fontColor(AppColors.GRAY_500)
        .margin({ bottom: 28 })

      Row() {
        Text('正在进入')
          .fontSize(13)
          .fontColor(this.themeColor)

        Text('  ···')
          .fontSize(13)
          .fontColor(this.themeColor)
      }

      Blank()

      Text('让时间安排更清晰')
        .fontSize(13)
        .fontColor(AppColors.GRAY_400)
        .margin({ bottom: 26 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.PAGE_BG)
    .alignItems(HorizontalAlign.Center)
  }
}
