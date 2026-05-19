export interface TodoTask {
  id: number
  title: string
  priority: string
  date: string
  startTime: string
  endTime: string
  done: boolean
  createDate: string
}

export interface NoteItem {
  id: number
  title: string
  content: string
  category: string
  date: string
  startTime: string
  endTime: string
  createDate: string
}

export interface HabitData {
  id: number
  title: string
  target: string
  days: number
  targetDays: number
  date: string
  startTime: string
  endTime: string
  checkedDate: string
  checkedDates: string[]
  createDate: string
}

export interface CalendarItem {
  id: number
  type: string
  title: string
  date: string
  startTime: string
  endTime: string
  description: string
  done: boolean
}

export interface CalendarDay {
  date: string
  day: number
  isCurrentMonth: boolean
  isToday: boolean
  isSelected: boolean
  itemCount: number
  doneCount: number
}

export interface FocusRecord {
  id: number
  taskId: number
  taskTitle: string
  durationMinutes: number
  date: string
  startTime: string
  endTime: string
  createTime: number
}
