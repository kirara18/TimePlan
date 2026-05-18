import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { NoteItem } from '../model/AppModels'
import { StatBox } from '../components/StatBox'

@Component
export struct NotePage {
  @Prop themeColor: string = '#4F7CFF'
  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
  dataPreferences: preferences.Preferences | null = null

  readonly STORE_NAME: string = 'time_plan_store'
  readonly NOTES_KEY: string = 'note_items'
  readonly NOTE_NEXT_ID_KEY: string = 'note_items_next_id'

  @State showAddPanel: boolean = false
  @State noteSearchText: string = ''
  @State noteTitle: string = ''
  @State noteContent: string = ''
  @State noteCategory: string = ''
  @State noteDate: string = ''
  @State noteStartTime: string = ''
  @State noteEndTime: string = ''
  @State transferTip: string = '便签可设置日期和时间，并同步显示到日历页'

  @State noteNextId: number = 3
  @State notes: NoteItem[] = [
    {
      id: 1,
      title: '课程重点',
      content: 'ArkTS、Stage 模型、UIAbility、页面路由、Preferences 本地存储。',
      category: '学习',
      date: '2026-05-17',
      startTime: '16:00',
      endTime: '16:30',
      createDate: '2026-05-17'
    },
    {
      id: 2,
      title: 'App 亮点',
      content: '日历汇总、模块联动、主题切换、本地保存。',
      category: '项目',
      date: '2026-05-18',
      startTime: '19:00',
      endTime: '19:30',
      createDate: '2026-05-17'
    }
  ]

  aboutToAppear(): void {
    this.initPreferencesAndLoad().then(() => {
      console.info('便签页数据加载完成')
    }).catch(() => {
      console.error('便签页数据加载失败')
    })
  }

  build() {
    Scroll() {
      Column() {
        Text('便签')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2937')
          .margin({ top: 30, bottom: 8 })

        Text('建立便签时可以填写日期与时间')
          .fontSize(15)
          .fontColor('#6B7280')
          .margin({ bottom: 8 })

        Text(this.transferTip)
          .fontSize(13)
          .fontColor(this.themeColor)
          .margin({ bottom: 20 })

        TextInput({ text: this.noteSearchText, placeholder: '搜索便签标题、内容或分类...' })
          .width('100%')
          .height(44)
          .backgroundColor('#FFFFFF')
          .borderRadius(14)
          .padding({ left: 14, right: 14 })
          .margin({ bottom: 20 })
          .onChange((value: string) => {
            this.noteSearchText = value
          })

        Column() {
          Text('便签概览')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')
            .margin({ bottom: 14 })

          Row() {
            StatBox({ themeColor: this.themeColor, title: '总数', value: this.notes.length.toString() })
            StatBox({ themeColor: this.themeColor, title: '学习', value: this.getCategoryCount('学习').toString() })
            StatBox({ themeColor: this.themeColor, title: '项目', value: this.getCategoryCount('项目').toString() })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .margin({ bottom: 18 })

        Button(this.showAddPanel ? '收起新建便签' : '+ 新建便签')
          .width('100%')
          .height(48)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(this.themeColor)
          .borderRadius(16)
          .margin({ bottom: 14 })
          .onClick(() => {
            this.showAddPanel = !this.showAddPanel
            if (this.noteDate.trim().length === 0) {
              this.noteDate = this.getToday()
            }
          })

        if (this.showAddPanel) {
          Column() {
            Text('新建便签')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111827')
              .margin({ bottom: 12 })

            TextInput({ text: this.noteTitle, placeholder: '请输入便签标题' })
              .width('100%')
              .height(44)
              .backgroundColor('#F9FAFB')
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.noteTitle = value
              })

            TextInput({ text: this.noteContent, placeholder: '请输入便签内容' })
              .width('100%')
              .height(90)
              .backgroundColor('#F9FAFB')
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.noteContent = value
              })

            TextInput({ text: this.noteCategory, placeholder: '请输入分类，例如：学习 / 项目 / 生活' })
              .width('100%')
              .height(44)
              .backgroundColor('#F9FAFB')
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.noteCategory = value
              })

            TextInput({ text: this.noteDate, placeholder: '请输入日期，例如：2026-05-17 或 19' })
              .width('100%')
              .height(44)
              .backgroundColor('#F9FAFB')
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.noteDate = value
              })

            Row() {
              TextInput({ text: this.noteStartTime, placeholder: '开始 09:00' })
                .layoutWeight(1)
                .height(44)
                .backgroundColor('#F9FAFB')
                .borderRadius(12)
                .padding({ left: 12, right: 12 })
                .margin({ right: 6 })
                .onChange((value: string) => {
                  this.noteStartTime = value
                })

              TextInput({ text: this.noteEndTime, placeholder: '结束 10:00' })
                .layoutWeight(1)
                .height(44)
                .backgroundColor('#F9FAFB')
                .borderRadius(12)
                .padding({ left: 12, right: 12 })
                .margin({ left: 6 })
                .onChange((value: string) => {
                  this.noteEndTime = value
                })
            }
            .width('100%')
            .margin({ bottom: 14 })

            Button('保存便签')
              .width('100%')
              .height(44)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .backgroundColor('#22C55E')
              .borderRadius(12)
              .onClick(() => {
                this.addNote()
              })
          }
          .width('100%')
          .padding(18)
          .backgroundColor('#FFFFFF')
          .borderRadius(18)
          .margin({ bottom: 18 })
        }

        Column() {
          Text('便签列表')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')
            .margin({ bottom: 12 })

          if (this.getFilteredNotes().length === 0) {
            Column() {
              Text('暂无匹配便签')
                .fontSize(16)
                .fontColor('#9CA3AF')
                .margin({ top: 20, bottom: 20 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          } else {
            ForEach(this.getFilteredNotes(), (item: NoteItem) => {
              this.NoteItemCard(item)
            }, (item: NoteItem) => item.id.toString())
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
  NoteItemCard(note: NoteItem) {
    Column() {
      Row() {
        Text(note.title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111827')
          .layoutWeight(1)

        Text('#' + note.category)
          .fontSize(12)
          .fontColor(this.themeColor)
          .backgroundColor('#EEF2FF')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(8)
      }
      .width('100%')
      .margin({ bottom: 8 })

      Text(note.content)
        .fontSize(14)
        .fontColor('#6B7280')
        .margin({ bottom: 8 })

      Text('日期：' + this.safeText(note.date, '未设置') + '    时间：' + this.safeText(note.startTime, '未设置') + ' - ' + this.safeText(note.endTime, '未设置'))
        .fontSize(13)
        .fontColor(this.themeColor)
        .margin({ bottom: 12 })

      Button('删除')
        .width('100%')
        .height(36)
        .fontSize(13)
        .backgroundColor('#EF4444')
        .borderRadius(12)
        .onClick(() => {
          this.deleteNote(note.id)
        })
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#F9FAFB')
    .borderRadius(12)
    .margin({ bottom: 10 })
    .alignItems(HorizontalAlign.Start)
  }

  async initPreferencesAndLoad(): Promise<void> {
    await this.initPreferences()
    await this.loadNotes()
  }

  async initPreferences(): Promise<void> {
    if (this.dataPreferences !== null) {
      return
    }

    this.dataPreferences = await preferences.getPreferences(this.context, {
      name: this.STORE_NAME
    })
  }

  async loadNotes(): Promise<void> {
    if (this.dataPreferences === null) {
      return
    }

    let notesValue = await this.dataPreferences.get(this.NOTES_KEY, '')
    if (typeof notesValue === 'string' && notesValue.length > 0) {
      try {
        let parsedNotes = JSON.parse(notesValue) as NoteItem[]
        this.notes = this.normalizeNotes(parsedNotes)
      } catch (err) {
        console.error('读取便签失败')
      }
    }

    let nextIdValue = await this.dataPreferences.get(this.NOTE_NEXT_ID_KEY, 3)
    if (typeof nextIdValue === 'number') {
      this.noteNextId = nextIdValue
    }
  }

  normalizeNotes(list: NoteItem[]): NoteItem[] {
    let result: NoteItem[] = []
    list.forEach((item: NoteItem) => {
      result.push({
        id: item.id,
        title: item.title,
        content: this.safeText(item.content, '暂无内容'),
        category: this.safeText(item.category, '默认'),
        date: this.normalizeDateInput(this.safeText(item.date, this.getToday())),
        startTime: this.safeText(item.startTime, '未设置'),
        endTime: this.safeText(item.endTime, '未设置'),
        createDate: this.safeText(item.createDate, this.getToday())
      })
    })
    return result
  }

  async saveNotes(): Promise<void> {
    if (this.dataPreferences === null) {
      await this.initPreferences()
    }

    if (this.dataPreferences === null) {
      return
    }

    await this.dataPreferences.put(this.NOTES_KEY, JSON.stringify(this.notes))
    await this.dataPreferences.put(this.NOTE_NEXT_ID_KEY, this.noteNextId)
    await this.dataPreferences.flush()
  }


  getFilteredNotes(): NoteItem[] {
    if (this.noteSearchText.trim().length === 0) {
      return this.notes
    }

    let keyword = this.noteSearchText.trim().toLowerCase()

    return this.notes.filter((item: NoteItem) => {
      return item.title.toLowerCase().includes(keyword)
        || item.content.toLowerCase().includes(keyword)
        || item.category.toLowerCase().includes(keyword)
        || item.date.toLowerCase().includes(keyword)
        || item.startTime.toLowerCase().includes(keyword)
        || item.endTime.toLowerCase().includes(keyword)
    })
  }

  addNote(): void {
    if (this.noteTitle.trim().length === 0) {
      return
    }

    let newNote: NoteItem = {
      id: this.noteNextId,
      title: this.noteTitle,
      content: this.noteContent.trim().length === 0 ? '暂无内容' : this.noteContent,
      category: this.noteCategory.trim().length === 0 ? '默认' : this.noteCategory,
      date: this.normalizeDateInput(this.noteDate),
      startTime: this.noteStartTime.trim().length === 0 ? '未设置' : this.noteStartTime,
      endTime: this.noteEndTime.trim().length === 0 ? '未设置' : this.noteEndTime,
      createDate: this.getToday()
    }

    this.notes = [newNote, ...this.notes]
    this.noteNextId = this.noteNextId + 1

    this.noteTitle = ''
    this.noteContent = ''
    this.noteCategory = ''
    this.noteDate = this.getToday()
    this.noteStartTime = ''
    this.noteEndTime = ''
    this.showAddPanel = false

    this.saveNotes().then(() => {
      console.info('便签保存成功')
    }).catch(() => {
      console.error('便签保存失败')
    })
  }

  deleteNote(id: number): void {
    this.notes = this.notes.filter((item: NoteItem) => {
      return item.id !== id
    })

    this.saveNotes().then(() => {
      console.info('便签删除后已保存')
    }).catch(() => {
      console.error('便签删除后保存失败')
    })
  }

  getCategoryCount(category: string): number {
    return this.notes.filter((item: NoteItem) => {
      return item.category === category
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
