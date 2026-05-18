import { CalendarPage } from './CalendarPage'
import { PlanPage } from './PlanPage'
import { NotePage } from './NotePage'
import { CheckPage } from './CheckPage'
import { MinePage } from './MinePage'
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
