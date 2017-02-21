'use strict'

const { seq, compose, cat, map, keep } = require('transducers.js')
const { createSelector: memo } = require('reselect')
const { getSelectedItems } = require('./items')
const { getVisiblePhotos } = require('./photos')

const getNotes = ({ notes }) => notes

const getVisibleNotes = memo(
  getNotes,
  getSelectedItems,
  getVisiblePhotos,

  (notes, ...parents) =>
    seq(parents, compose(
      cat,
      map(parent => parent.notes),
      cat,
      map(id => notes[id]),
      keep()
    ))
)


module.exports = {
  getVisibleNotes
}