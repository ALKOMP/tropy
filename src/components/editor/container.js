'use strict'

const React = require('react')
const { PureComponent } = React
const { func, bool, object, number, string } = require('prop-types')
const { EditorToolbar } = require('./toolbar')
const { EditorState } = require('prosemirror-state')
const { EditorView } = require('./view')
const { Placeholder } = require('../placeholder')
const { schema } = require('./schema')
const commands = require('./commands')(schema)
const plugins = require('./plugins')(schema)
const { match } = require('../../keymap')
const cx = require('classnames')
const { get, noop } = require('../../common/util')


class Editor extends PureComponent {
  constructor(props) {
    super(props)
    this.state = {}
  }

  setContainer = (container) => {
    this.container = container
  }

  setView = (view) => {
    this.view = get(view, ['pm'])
  }

  setToolbar = (toolbar) => {
    this.toolbar = toolbar
  }

  get classes() {
    return {
      'editor': true,
      'is-blurred': !this.state.hasViewFocus
    }
  }

  getEditorState({ state } = this.props) {
    if (state == null) {
      return EditorState.create({ schema, plugins })
    }

    if (state instanceof EditorState) {
      return state
    }

    return EditorState.fromJSON({ schema, plugins }, state)
  }

  isBlank(doc) {
    if (doc.childCount !== 1) return false
    if (!doc.firstChild.isTextblock) return false
    if (doc.firstChild.content.size !== 0) return false
    return true
  }

  focus = () => {
    this.view.focus()
  }

  exec(action, ...args) {
    return (commands[action] || noop)(
      this.view.state, this.view.dispatch, ...args
    )
  }

  handleChange = (tr) => {
    this.props.onChange(this.view.state.apply(tr), tr.docChanged)
  }

  handleKeyDown = (_, event) => {
    const action = match(this.props.keymap, event)

    switch (action) {
      case null:
        return
      case 'addLink':
        this.toolbar.setLinkContext()
        break
      default:
        if (!this.exec(action)) return
    }

    event.stopPropagation()
    return true
  }

  handleFocus = (event) => {
    if (event.target === this.container) {
      setTimeout(this.focus, 0)
    }
  }

  handleCommand = (...args) => {
    if (this.exec(...args)) {
      if (!this.state.hasViewFocus) this.focus()
    }
  }

  handleViewFocus = () => {
    this.setState({ hasViewFocus: true })
  }

  handleViewBlur = () => {
    this.setState({ hasViewFocus: false })
    this.props.onBlur()
  }

  render() {
    const { isDisabled, placeholder, tabIndex } = this.props
    const state = this.getEditorState()
    const showPlaceholder = placeholder != null && this.isBlank(state.doc)

    return (
      <div
        ref={this.setContainer}
        className={cx(this.classes)}
        tabIndex={-1}
        onFocus={this.handleFocus}>
        {!isDisabled &&
          <EditorToolbar
            state={state}
            ref={this.setToolbar}
            onCommand={this.handleCommand}/>
        }

        <div className="scroll-container">
          {showPlaceholder && <Placeholder id={placeholder}/>}
          <EditorView
            ref={this.setView}
            state={state}
            isDisabled={isDisabled}
            tabIndex={tabIndex}
            onFocus={this.handleViewFocus}
            onBlur={this.handleViewBlur}
            onChange={this.handleChange}
            onKeyDown={this.handleKeyDown}/>
        </div>
      </div>
    )
  }

  static propTypes = {
    isDisabled: bool,
    keymap: object.isRequired,
    onBlur: func.isRequired,
    onChange: func.isRequired,
    placeholder: string,
    state: object,
    tabIndex: number.isRequired
  }

  static defaultProps = {
    tabIndex: -1
  }
}

module.exports = {
  Editor
}
