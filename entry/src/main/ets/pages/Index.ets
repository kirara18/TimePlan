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
        FocusPage({ themeColor: this.themeColor })
      }
      .tabBar('专注')

      TabContent() {
        ReviewPage({ themeColor: this.themeColor })
      }
      .tabBar('统计')

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
    .backgroundColor(AppColors.GRAY_BLUE_50)
    .onChange((index: number) => {
      this.currentIndex = index
    })
  }
}
