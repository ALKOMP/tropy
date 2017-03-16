'use strict'

const cmd  = require('prosemirror-commands')
const { undo, redo } = require('prosemirror-history')
const {
  wrapInList, splitListItem, liftListItem, sinkListItem
} = require('prosemirror-schema-list')


module.exports = (schema) => {
  const list = {
    wrapInOrderedList: wrapInList(schema.nodes.ordered_list),
    wrapInBulletList: wrapInList(schema.nodes.bullet_list),
    splitListItem: splitListItem(schema.nodes.list_item),
    liftListItem: liftListItem(schema.nodes.list_item),
    sinkListItem: sinkListItem(schema.nodes.list_item),
  }

  return {
    ...cmd,
    ...list,

    undo,
    redo,

    bold: cmd.toggleMark(schema.marks.strong),
    italic: cmd.toggleMark(schema.marks.em),
    underline: cmd.toggleMark(schema.marks.underline),
    strike: cmd.toggleMark(schema.marks.strikethrough),

    wrapInBlockQuote: cmd.wrapIn(schema.nodes.blockquote),

    break: cmd.chainCommands(
      list.splitListItem,
      cmd.createParagraphNear,
      cmd.liftEmptyBlock,
      cmd.splitBlock
    ),

    hardBreak: (state, dispatch) => (
      dispatch(
        state
          .tr
          .replaceSelectionWith(schema.nodes.hard_break.create())
          .scrollIntoView()
      ), true
    ),

    backspace: cmd.chainCommands(
      cmd.deleteSelection,
      cmd.joinBackward
    ),

    del: cmd.chainCommands(
      cmd.deleteSelection,
      cmd.joinForward
    )
  }
}