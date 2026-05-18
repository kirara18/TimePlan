import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { TodoTask } from '../model/AppModels'
import { StatBox } from '../components/StatBox'

@Component
export struct PlanPage {
  @Prop themeColor: string = '#4F7CFF'

  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
  dataPreferences: preferences.Preferences | null = null

  readonly STORE_NAME: string = 'time_plan_store'
  readonly TASKS_KEY: string = 'plan_tasks'
  readonly TASK_NEXT_ID_KEY: string = 'plan_tasks_next_id'

  @State showAddPanel: boolean = false
  @State taskTitle: string = ''
  @State taskPriority: string = ''
  @State taskDate: string = ''
  @State taskStartTime: string = ''
  @State taskEndTime: string = ''
  @State taskSearchText: string = ''

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
          .fontColor('#1F2937')
          .margin({ top: 30, bottom: 8 })

        Text('建立待办时填写日期、开始时间和结束时间')
          .fontSize(15)
          .fontColor('#6B7280')
          .margin({ bottom: 20 })

        TextInput({ text: this.taskSearchText, placeholder: '搜索待办任务...' })
          .width('100%')
          .height(44)
          .backgroundColor('#FFFFFF')
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
            .fontColor('#111827')
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
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .margin({ bottom: 18 })

        Button(this.showAddPanel ? '收起新增任务' : '+ 新增待办')
          .width('100%')
          .height(48)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(this.themeColor)
          .borderRadius(16)
          .margin({ bottom: 14 })
          .onClick(() => {
            this.showAddPanel = !this.showAddPanel
            if (this.taskDate.trim().length === 0) {
              this.taskDate = this.getToday()
            }
          })

        if (this.showAddPanel) {
          Column() {
            Text('新增待办任务')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111827')
              .margin({ bottom: 12 })

            TextInput({ text: this.taskTitle, placeholder: '请输入任务名称，例如：完成课程报告' })
              .width('100%')
              .height(44)
              .backgroundColor('#F9FAFB')
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.taskTitle = value
              })

            TextInput({ text: this.taskPriority, placeholder: '请输入优先级：高 / 中 / 低' })
              .width('100%')
              .height(44)
              .backgroundColor('#F9FAFB')
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.taskPriority = value
              })

            TextInput({ text: this.taskDate, placeholder: '请输入日期，例如：2026-05-17 或 19' })
              .width('100%')
              .height(44)
              .backgroundColor('#F9FAFB')
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.taskDate = value
              })

            Row() {
              TextInput({ text: this.taskStartTime, placeholder: '开始 09:00' })
                .layoutWeight(1)
                .height(44)
                .backgroundColor('#F9FAFB')
                .borderRadius(12)
                .padding({ left: 12, right: 12 })
                .margin({ right: 6 })
                .onChange((value: string) => {
                  this.taskStartTime = value
                })

              TextInput({ text: this.taskEndTime, placeholder: '结束 10:00' })
                .layoutWeight(1)
                .height(44)
                .backgroundColor('#F9FAFB')
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
              .backgroundColor('#22C55E')
              .borderRadius(12)
              .onClick(() => {
                this.addTask()
              })
          }
          .width('100%')
          .padding(18)
          .backgroundColor('#FFFFFF')
          .borderRadius(18)
          .margin({ bottom: 18 })
        }

        Column() {
          Text('待办任务')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')
            .margin({ bottom: 12 })

          if (this.getFilteredTasks().length === 0) {
            Column() {
              Text('暂无匹配任务')
                .fontSize(16)
                .fontColor('#9CA3AF')
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
  TaskCard(task: TodoTask) {
    Column() {
      Row() {
        Text(task.done ? '✓' : '○')
          .fontSize(24)
          .fontColor(task.done ? '#22C55E' : '#9CA3AF')
          .margin({ right: 10 })

        Column() {
          Text(task.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(task.done ? '#9CA3AF' : '#111827')

          Text('日期：' + this.safeText(task.date, '未设置') + '    时间：' + this.safeText(task.startTime, '未设置') + ' - ' + this.safeText(task.endTime, '未设置'))
            .fontSize(13)
            .fontColor(this.themeColor)
            .margin({ top: 4 })

          Text('优先级：' + task.priority + '    状态：' + (task.done ? '已完成' : '未完成'))
            .fontSize(12)
            .fontColor('#6B7280')
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
          .backgroundColor(task.done ? '#9CA3AF' : '#22C55E')
          .borderRadius(12)
          .margin({ right: 8 })
          .onClick(() => {
            this.toggleTask(task.id)
          })

        Button('删除')
          .layoutWeight(1)
          .height(38)
          .fontSize(14)
          .backgroundColor('#EF4444')
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
    .backgroundColor(task.done ? '#F0FDF4' : '#F9FAFB')
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

    this.dataPreferences = await preferences.getPreferences(this.context, {
      name: this.STORE_NAME
    })
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
        priority: this.safeText(item.priority, '中'),
        date: this.normalizeDateInput(this.safeText(item.date, this.getToday())),
        startTime: this.safeText(item.startTime, '未设置'),
        endTime: this.safeText(item.endTime, '未设置'),
        done: item.done,
        createDate: this.safeText(item.createDate, this.getToday())
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
      date: this.normalizeDateInput(this.taskDate),
      startTime: this.taskStartTime.trim().length === 0 ? '未设置' : this.taskStartTime,
      endTime: this.taskEndTime.trim().length === 0 ? '未设置' : this.taskEndTime,
      done: false,
      createDate: this.getToday()
    }

    this.tasks = [newTask, ...this.tasks]
    this.taskNextId = this.taskNextId + 1

    this.taskTitle = ''
    this.taskPriority = ''
    this.taskDate = this.getToday()
    this.taskStartTime = ''
    this.taskEndTime = ''
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
        let now = new Date()
        return this.formatDate(now.getFullYear(), now.getMonth() + 1, Math.floor(day))
      }
    }

    if (parts.length === 2) {
      let month = Number(parts[0])
      let day = Number(parts[1])
      if (!isNaN(month) && !isNaN(day)) {
        let now = new Date()
        return this.formatDate(now.getFullYear(), Math.floor(month), Math.floor(day))
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

  addDays(dateText: string, count: number): string {
    let year = Number(dateText.substring(0, 4))
    let month = Number(dateText.substring(5, 7))
    let day = Number(dateText.substring(8, 10))
    let date = new Date(year, month - 1, day + count)
    return this.formatDate(date.getFullYear(), date.getMonth() + 1, date.getDate())
  }

  formatDate(year: number, month: number, day: number): string {
    let monthText = month < 10 ? '0' + month.toString() : month.toString()
    let dayText = day < 10 ? '0' + day.toString() : day.toString()
    return year.toString() + '-' + monthText + '-' + dayText
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
