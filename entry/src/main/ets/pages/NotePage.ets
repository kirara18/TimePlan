//本文件不再使用

import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { NoteItem } from '../model/AppModels'
import { StatBox } from '../components/StatBox'
import { safeText, getToday, normalizeDateInput } from '../utils/DateUtil'
import { STORE_NAME as TIME_PLAN_STORE_NAME, NOTES_KEY as PLAN_NOTES_KEY, NOTE_NEXT_ID_KEY as PLAN_NOTE_NEXT_ID_KEY } from '../utils/StoreConstants'
import { getTimePlanPreferences } from '../utils/PreferenceUtil'
import { AppColors } from '../utils/AppColors'

@Component
export struct NotePage {
  @Prop themeColor: string = AppColors.BLUE
  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
  dataPreferences: preferences.Preferences | null = null

  readonly STORE_NAME: string = TIME_PLAN_STORE_NAME
  readonly NOTES_KEY: string = PLAN_NOTES_KEY
  readonly NOTE_NEXT_ID_KEY: string = PLAN_NOTE_NEXT_ID_KEY

  @State showAddPanel: boolean = false
  @State noteSearchText: string = ''
  @State noteTitle: string = ''
  @State noteContent: string = ''
  @State noteCategory: string = ''
  @State noteDate: string = ''
  @State noteStartTime: string = ''
  @State noteEndTime: string = ''
  @State transferTip: string = '便签可设置日期和时间，并同步显示到日历页'

  @State noteNextId: number = 1
  @State notes: NoteItem[] = []

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
          .fontColor(AppColors.GRAY_800)
          .margin({ top: 30, bottom: 8 })

        Text('建立便签时可以填写日期与时间')
          .fontSize(15)
          .fontColor(AppColors.GRAY_500)
          .margin({ bottom: 8 })

        Text(this.transferTip)
          .fontSize(13)
          .fontColor(this.themeColor)
          .margin({ bottom: 20 })

        TextInput({ text: this.noteSearchText, placeholder: '搜索便签标题、内容或分类...' })
          .width('100%')
          .height(44)
          .fontColor(AppColors.INPUT_TEXT)
          .placeholderColor(AppColors.INPUT_PLACEHOLDER)
          .backgroundColor(AppColors.INPUT_BG)
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
            .fontColor(AppColors.GRAY_900)
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
        .backgroundColor(AppColors.CARD_BG)
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
              this.noteDate = getToday()
            }
          })

        if (this.showAddPanel) {
          Column() {
            Text('新建便签')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.GRAY_900)
              .margin({ bottom: 12 })

            TextInput({ text: this.noteTitle, placeholder: '请输入便签标题' })
              .width('100%')
              .height(44)
              .fontColor(AppColors.INPUT_TEXT)
              .placeholderColor(AppColors.INPUT_PLACEHOLDER)
              .backgroundColor(AppColors.INPUT_BG)
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.noteTitle = value
              })

            TextInput({ text: this.noteContent, placeholder: '请输入便签内容' })
              .width('100%')
              .height(90)
              .fontColor(AppColors.INPUT_TEXT)
              .placeholderColor(AppColors.INPUT_PLACEHOLDER)
              .backgroundColor(AppColors.INPUT_BG)
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.noteContent = value
              })

            TextInput({ text: this.noteCategory, placeholder: '请输入分类，例如：学习 / 项目 / 生活' })
              .width('100%')
              .height(44)
              .fontColor(AppColors.INPUT_TEXT)
              .placeholderColor(AppColors.INPUT_PLACEHOLDER)
              .backgroundColor(AppColors.INPUT_BG)
              .borderRadius(12)
              .padding({ left: 12, right: 12 })
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.noteCategory = value
              })

            TextInput({ text: this.noteDate, placeholder: '请输入日期，例如：2026-05-17 或 19' })
              .width('100%')
              .height(44)
              .fontColor(AppColors.INPUT_TEXT)
              .placeholderColor(AppColors.INPUT_PLACEHOLDER)
              .backgroundColor(AppColors.INPUT_BG)
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
                .fontColor(AppColors.INPUT_TEXT)
                .placeholderColor(AppColors.INPUT_PLACEHOLDER)
                .backgroundColor(AppColors.INPUT_BG)
                .borderRadius(12)
                .padding({ left: 12, right: 12 })
                .margin({ right: 6 })
                .onChange((value: string) => {
                  this.noteStartTime = value
                })

              TextInput({ text: this.noteEndTime, placeholder: '结束 10:00' })
                .layoutWeight(1)
                .height(44)
                .fontColor(AppColors.INPUT_TEXT)
                .placeholderColor(AppColors.INPUT_PLACEHOLDER)
                .backgroundColor(AppColors.INPUT_BG)
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
              .backgroundColor(AppColors.GREEN)
              .borderRadius(12)
              .onClick(() => {
                this.addNote()
              })
          }
          .width('100%')
          .padding(18)
          .backgroundColor(AppColors.CARD_BG)
          .borderRadius(18)
          .margin({ bottom: 18 })
        }

        Column() {
          Text('便签列表')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
            .margin({ bottom: 12 })

          if (this.getFilteredNotes().length === 0) {
            Column() {
              Text('暂无匹配便签')
                .fontSize(16)
                .fontColor(AppColors.GRAY_400)
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
  NoteItemCard(note: NoteItem) {
    Column() {
      Row() {
        Text(note.title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.GRAY_900)
          .layoutWeight(1)

        Text('#' + note.category)
          .fontSize(12)
          .fontColor(this.themeColor)
          .backgroundColor(AppColors.INDIGO_50)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(8)
      }
      .width('100%')
      .margin({ bottom: 8 })

      Text(note.content)
        .fontSize(14)
        .fontColor(AppColors.GRAY_500)
        .margin({ bottom: 8 })

      Text('日期：' + safeText(note.date, '未设置') + '    时间：' + safeText(note.startTime, '未设置') + ' - ' + safeText(note.endTime, '未设置'))
        .fontSize(13)
        .fontColor(this.themeColor)
        .margin({ bottom: 12 })

      Button('删除')
        .width('100%')
        .height(36)
        .fontSize(13)
        .backgroundColor(AppColors.RED)
        .borderRadius(12)
        .onClick(() => {
          this.deleteNote(note.id)
        })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(AppColors.SURFACE_BG)
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

    this.dataPreferences = await getTimePlanPreferences(this.context)
  }

  async loadNotes(): Promise<void> {
    this.dataPreferences = await getTimePlanPreferences(this.context)

    if (this.dataPreferences === null) {
      this.notes = []
      this.noteNextId = 1
      return
    }

    let loadedNotes: NoteItem[] = []
    let notesValue = await this.dataPreferences.get(this.NOTES_KEY, '')
    if (typeof notesValue === 'string' && notesValue.length > 0) {
      try {
        let parsedNotes = JSON.parse(notesValue) as NoteItem[]
        loadedNotes = this.normalizeNotes(parsedNotes)
      } catch (err) {
        console.error('读取便签失败')
      }
    }

    this.notes = loadedNotes

    let nextIdValue = await this.dataPreferences.get(this.NOTE_NEXT_ID_KEY, 1)
    if (typeof nextIdValue === 'number') {
      this.noteNextId = nextIdValue
    } else {
      this.noteNextId = 1
    }
  }

  normalizeNotes(list: NoteItem[]): NoteItem[] {
    let result: NoteItem[] = []
    list.forEach((item: NoteItem) => {
      result.push({
        id: item.id,
        title: item.title,
        content: safeText(item.content, '暂无内容'),
        category: safeText(item.category, '默认'),
        date: normalizeDateInput(safeText(item.date, getToday())),
        startTime: safeText(item.startTime, '未设置'),
        endTime: safeText(item.endTime, '未设置'),
        createDate: safeText(item.createDate, getToday())
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
      date: normalizeDateInput(this.noteDate),
      startTime: this.noteStartTime.trim().length === 0 ? '未设置' : this.noteStartTime,
      endTime: this.noteEndTime.trim().length === 0 ? '未设置' : this.noteEndTime,
      createDate: getToday()
    }

    this.notes = [newNote, ...this.notes]
    this.noteNextId = this.noteNextId + 1

    this.noteTitle = ''
    this.noteContent = ''
    this.noteCategory = ''
    this.noteDate = getToday()
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

}
