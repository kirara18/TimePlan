import { common } from '@kit.AbilityKit'
import { TodoTask, NoteItem, HabitData } from '../model/AppModels'
import { safeText, getToday, normalizeDateInput } from '../utils/DateUtil'
import {
  TASKS_KEY,
  TASK_NEXT_ID_KEY,
  NOTES_KEY,
  NOTE_NEXT_ID_KEY,
  HABITS_KEY,
  HABIT_NEXT_ID_KEY
} from '../utils/StoreConstants'
import { getTimePlanPreferences } from '../utils/PreferenceUtil'

export interface PlanStorageLoadResult {
  tasks: TodoTask[]
  taskNextId: number
  notes: NoteItem[]
  noteNextId: number
  checks: HabitData[]
  checkNextId: number
}

export class PlanStorageService {
  static async loadAllPlanData(
    context: common.UIAbilityContext,
    defaultTasks: TodoTask[],
    defaultTaskNextId: number,
    defaultNotes: NoteItem[],
    defaultNoteNextId: number,
    defaultChecks: HabitData[],
    defaultCheckNextId: number
  ): Promise<PlanStorageLoadResult> {
    let dataPreferences = await getTimePlanPreferences(context)

    let result: PlanStorageLoadResult = {
      tasks: [],
      taskNextId: 1,
      notes: [],
      noteNextId: 1,
      checks: [],
      checkNextId: 1
    }

    let tasksValue = await dataPreferences.get(TASKS_KEY, '')
    if (typeof tasksValue === 'string' && tasksValue.length > 0) {
      try {
        let parsedTasks = JSON.parse(tasksValue) as TodoTask[]
        result.tasks = PlanStorageService.normalizeTasks(parsedTasks)
      } catch (err) {
        console.error('读取 Task 失败')
      }
    }

    let taskNextIdValue = await dataPreferences.get(TASK_NEXT_ID_KEY, defaultTaskNextId)
    if (typeof taskNextIdValue === 'number') {
      result.taskNextId = taskNextIdValue
    }

    let notesValue = await dataPreferences.get(NOTES_KEY, '')
    if (typeof notesValue === 'string' && notesValue.length > 0) {
      try {
        let parsedNotes = JSON.parse(notesValue) as NoteItem[]
        result.notes = PlanStorageService.normalizeNotes(parsedNotes)
      } catch (err) {
        console.error('读取 Note 失败')
      }
    }

    let noteNextIdValue = await dataPreferences.get(NOTE_NEXT_ID_KEY, defaultNoteNextId)
    if (typeof noteNextIdValue === 'number') {
      result.noteNextId = noteNextIdValue
    }

    let checksValue = await dataPreferences.get(HABITS_KEY, '')
    if (typeof checksValue === 'string' && checksValue.length > 0) {
      try {
        let parsedChecks = JSON.parse(checksValue) as HabitData[]
        result.checks = PlanStorageService.normalizeChecks(parsedChecks)
      } catch (err) {
        console.error('读取 Check 失败')
      }
    }

    let checkNextIdValue = await dataPreferences.get(HABIT_NEXT_ID_KEY, defaultCheckNextId)
    if (typeof checkNextIdValue === 'number') {
      result.checkNextId = checkNextIdValue
    }

    return result
  }

  static async saveTasks(context: common.UIAbilityContext, tasks: TodoTask[], taskNextId: number): Promise<void> {
    let dataPreferences = await getTimePlanPreferences(context)
    await dataPreferences.put(TASKS_KEY, JSON.stringify(tasks))
    await dataPreferences.put(TASK_NEXT_ID_KEY, taskNextId)
    await dataPreferences.flush()
  }

  static async saveNotes(context: common.UIAbilityContext, notes: NoteItem[], noteNextId: number): Promise<void> {
    let dataPreferences = await getTimePlanPreferences(context)
    await dataPreferences.put(NOTES_KEY, JSON.stringify(notes))
    await dataPreferences.put(NOTE_NEXT_ID_KEY, noteNextId)
    await dataPreferences.flush()
  }

  static async saveChecks(context: common.UIAbilityContext, checks: HabitData[], checkNextId: number): Promise<void> {
    let dataPreferences = await getTimePlanPreferences(context)
    await dataPreferences.put(HABITS_KEY, JSON.stringify(checks))
    await dataPreferences.put(HABIT_NEXT_ID_KEY, checkNextId)
    await dataPreferences.flush()
  }

  static normalizeTasks(list: TodoTask[]): TodoTask[] {
    let result: TodoTask[] = []

    list.forEach((item: TodoTask) => {
      result.push({
        id: item.id,
        title: item.title,
        priority: safeText(item.priority, '中'),
        date: normalizeDateInput(safeText(item.date, getToday())),
        startTime: safeText(item.startTime, '未设置'),
        endTime: safeText(item.endTime, '未设置'),
        done: item.done,
        createDate: safeText(item.createDate, getToday())
      })
    })

    return result
  }

  static normalizeNotes(list: NoteItem[]): NoteItem[] {
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

  static normalizeChecks(list: HabitData[]): HabitData[] {
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
}
