/* @ds-bundle: {"format":4,"namespace":"BepHoaLac","components":[{"name":"Button"},{"name":"Chip"},{"name":"SearchField"},{"name":"AvailabilityBadge"},{"name":"RecipeCard"},{"name":"BottomNav"},{"name":"EmptyState"},{"name":"StepTimer"},{"name":"ServingStepper"},{"name":"Icon"}]} */
(function () {
  var React = window.React;
  var h = React.createElement;

  function cx() {
    return Array.prototype.filter.call(arguments, Boolean).join(' ');
  }

  // 24px stroke icons in the Material Symbols Rounded spirit; swap for the real set in Flutter.
  var PATHS = {
    search: 'M11 4a7 7 0 1 0 0 14a7 7 0 1 0 0-14zM20 20l-4-4',
    clock: 'M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18zM12 7v5l3 2',
    person: 'M12 4a4 4 0 1 0 0 8a4 4 0 1 0 0-8zM4 20c1.5-3.5 4.5-5 8-5s6.5 1.5 8 5',
    heart: 'M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z',
    home: 'M4 11l8-7 8 7v9h-5v-6H9v6H4z',
    bowl: 'M3 11h18a9 9 0 0 1-18 0zM8 7c0-1.5 1-2 1-3.5M12 7c0-1.5 1-2 1-3.5M16 7c0-1.5 1-2 1-3.5',
    list: 'M5 6h14M5 12h14M5 18h9',
    plus: 'M12 5v14M5 12h14',
    check: 'M5 12l5 5 9-10',
    compass: 'M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18zM15.5 8.5l-2 5-5 2 2-5z',
    fridge: 'M8 3h8a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2zM6 10h12M9 6v2M9 13v3',
    calendar: 'M6 5h12a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2zM4 10h16M8 3v4M16 3v4',
    bookmark: 'M6 4h12v16l-6-4-6 4z',
    shuffle: 'M4 7h11l-3-3M20 17H9l3 3',
    back: 'M15 5l-7 7 7 7',
    sliders: 'M4 7h10M18 7h2M4 17h4M12 17h8M16 5a2 2 0 1 0 0 4a2 2 0 1 0 0-4zM10 15a2 2 0 1 0 0 4a2 2 0 1 0 0-4z',
    timer: 'M12 5a8 8 0 1 0 0 16a8 8 0 1 0 0-16zM12 9v4l2 2M9 2h6',
    minus: 'M5 12h14',
    close: 'M6 6l12 12M18 6L6 18',
    smile: 'M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18zM9 9.5v.5M15 9.5v.5M8.5 14a4 4 0 0 0 7 0',
    meh: 'M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18zM9 9.5v.5M15 9.5v.5M8.5 15h7',
    frown: 'M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18zM9 9.5v.5M15 9.5v.5M8.5 16.5a4 4 0 0 1 7 0',
    bell: 'M6 16v-5a6 6 0 0 1 12 0v5l2 2H4zM10 20a2 2 0 0 0 4 0',
    trash: 'M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13M10 11v6M14 11v6',
    chevron: 'M9 5l7 7-7 7',
    alert: 'M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18zM12 7.5v5.5M12 16.5v.5',
    info: 'M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18zM12 11v5.5M12 7.5v.5',
    shield: 'M12 3l7 3v5c0 4.5-3 8.5-7 10c-4-1.5-7-5.5-7-10V6z',
    mail: 'M4 6h16v12H4zM4 7l8 6 8-6',
    image: 'M5 4h14a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1zM4 16l5-5 4 4 3-3 4 4M15.5 8.5v.5',
    sun: 'M12 8a4 4 0 1 0 0 8a4 4 0 1 0 0-8zM12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4',
    moon: 'M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z',
    device: 'M8 2h8a2 2 0 0 1 2 2v16a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2zM11 18h2'
  };

  function Icon(props) {
    return h(
      'svg',
      { className: cx('bh-icon', props.className), viewBox: '0 0 24 24', 'aria-hidden': 'true' },
      h('path', { d: PATHS[props.name] || PATHS.bowl })
    );
  }

  function Button(props) {
    var variant = props.variant || 'primary';
    var rest = Object.assign({}, props);
    delete rest.variant; delete rest.icon; delete rest.block; delete rest.size; delete rest.className;
    return h(
      'button',
      Object.assign({ type: 'button' }, rest, {
        className: cx('bh-btn', 'bh-btn-' + variant, props.block && 'bh-btn-block', props.size === 'lg' && 'bh-btn-lg', props.className)
      }),
      props.icon && h(Icon, { name: props.icon }),
      props.children
    );
  }

  function Chip(props) {
    return h(
      'button',
      { type: 'button', className: 'bh-chip', 'aria-pressed': props.selected ? 'true' : 'false', onClick: props.onClick },
      props.selected ? h(Icon, { name: 'check' }) : props.icon && h(Icon, { name: props.icon }),
      props.children
    );
  }

  function SearchField(props) {
    return h(
      'label',
      { className: 'bh-search' },
      h(Icon, { name: 'search' }),
      h('input', {
        type: 'search',
        placeholder: props.placeholder || 'Tìm món, nguyên liệu…',
        value: props.value,
        defaultValue: props.value === undefined ? props.defaultValue : undefined,
        onChange: props.onChange,
        'aria-label': props.label || 'Tìm công thức'
      })
    );
  }

  function AvailabilityBadge(props) {
    var missing = props.missing || [];
    var ready = missing.length === 0;
    return h(
      'span',
      { className: cx('bh-avail', !ready && 'bh-avail-missing') },
      ready ? 'Đủ đồ' : 'Thiếu: ' + missing.join(', ')
    );
  }

  function RecipeCard(props) {
    var saved = !!props.saved;
    return h(
      'article',
      { className: 'bh-card' },
      h(
        'div',
        { className: 'bh-card-media' },
        props.image ? h('img', { src: props.image, alt: '' }) : h(Icon, { name: 'bowl' }),
        props.onToggleSave !== undefined &&
          h(
            'button',
            {
              type: 'button',
              className: 'bh-card-save',
              'aria-pressed': saved ? 'true' : 'false',
              'aria-label': saved ? 'Bỏ lưu' : 'Lưu công thức',
              onClick: props.onToggleSave
            },
            h(Icon, { name: 'bookmark' })
          )
      ),
      h(
        'div',
        { className: 'bh-card-body' },
        h('h3', { className: 'bh-card-title' }, props.title),
        h(
          'span',
          { className: 'bh-card-meta' },
          h(Icon, { name: 'clock' }),
          props.minutes + ' phút',
          props.servings ? ' · ' + props.servings + ' người' : null,
          props.tool ? ' · ' + props.tool : null
        ),
        props.missing !== undefined &&
          h('div', { className: 'bh-card-foot' }, h(AvailabilityBadge, { missing: props.missing }))
      )
    );
  }

  var NAV_ITEMS = [
    { id: 'home', label: 'Khám phá', icon: 'compass' },
    { id: 'pantry', label: 'Tủ đồ', icon: 'fridge' },
    { id: 'plan', label: 'Thực đơn', icon: 'calendar' },
    { id: 'saved', label: 'Đã lưu', icon: 'bookmark' }
  ];

  function BottomNav(props) {
    var items = props.items || NAV_ITEMS;
    return h(
      'nav',
      { className: 'bh-nav', 'aria-label': 'Điều hướng chính' },
      items.map(function (item) {
        var active = item.id === props.active;
        return h(
          'button',
          {
            key: item.id,
            type: 'button',
            className: 'bh-nav-item',
            'aria-current': active ? 'page' : undefined,
            onClick: props.onChange ? function () { props.onChange(item.id); } : undefined
          },
          h('span', { className: 'bh-nav-pill' }, h(Icon, { name: item.icon })),
          item.label
        );
      })
    );
  }

  function EmptyState(props) {
    return h(
      'div',
      { className: 'bh-empty' },
      h('div', { className: 'bh-empty-art' }, h(Icon, { name: props.icon || 'bowl' })),
      h('h3', { className: 'bh-empty-title' }, props.title),
      props.children && h('p', { className: 'bh-empty-text' }, props.children),
      props.actionLabel && h(Button, { variant: 'secondary', onClick: props.onAction }, props.actionLabel)
    );
  }

  function mmss(s) {
    var m = Math.floor(s / 60), r = s % 60;
    return (m < 10 ? '0' : '') + m + ':' + (r < 10 ? '0' : '') + r;
  }

  function durationLabel(s) {
    return s >= 60 && s % 60 === 0 ? s / 60 + ' phút' : s >= 60 ? mmss(s) : s + ' giây';
  }

  // Idle: a secondary button "Hẹn 3 phút". Running: a dark bar counting down. Done: the bar turns chili.
  function StepTimer(props) {
    var s = React.useState(props.autoStart ? props.seconds : null);
    var left = s[0], setLeft = s[1];
    React.useEffect(function () {
      if (left === null) return undefined;
      if (left <= 0) {
        if (props.onDone) props.onDone();
        return undefined;
      }
      var id = setTimeout(function () { setLeft(left - 1); }, 1000);
      return function () { clearTimeout(id); };
    }, [left]);

    // Tell the host screen when the timer starts, finishes or is cleared, so it can keep a running bar visible.
    var status = left === null ? 'idle' : left > 0 ? 'running' : 'done';
    var lastStatus = React.useRef(status);
    React.useEffect(function () {
      if (status === lastStatus.current) return;
      lastStatus.current = status;
      if (props.onStatusChange) props.onStatusChange(status);
    }, [status]);

    if (left === null) {
      return h(
        Button,
        { variant: 'secondary', icon: 'timer', onClick: function () { setLeft(props.seconds); } },
        'Hẹn ' + durationLabel(props.seconds)
      );
    }
    var done = left === 0;
    return h(
      'div',
      { className: cx('bh-timer', done && 'bh-timer-done'), role: 'timer', 'aria-live': 'polite' },
      h(
        'div',
        { className: 'bh-timer-text' },
        h('span', { className: 'bh-timer-label' }, done ? 'Hết giờ · ' + (props.label || '') : props.label),
        h('span', { className: 'bh-timer-time' }, done ? 'Xong!' : mmss(left))
      ),
      h('button', { type: 'button', className: 'bh-timer-btn', onClick: function () { setLeft(null); } }, done ? 'Tắt' : 'Dừng')
    );
  }

  function ServingStepper(props) {
    var min = props.min || 1;
    var max = props.max || 6;
    var unit = props.unit || 'người';
    var s = React.useState(props.defaultValue || min);
    var value = props.value !== undefined ? props.value : s[0];
    function set(v) {
      var next = Math.min(max, Math.max(min, v));
      if (props.value === undefined) s[1](next);
      if (props.onChange) props.onChange(next);
    }
    return h(
      'div',
      { className: 'bh-stepper', role: 'group', 'aria-label': props.label || 'Khẩu phần' },
      h(
        'button',
        { type: 'button', className: 'bh-stepper-btn', 'aria-label': 'Bớt một ' + unit, disabled: value <= min, onClick: function () { set(value - 1); } },
        h(Icon, { name: 'minus' })
      ),
      h('span', { className: 'bh-stepper-value', 'aria-live': 'polite' }, value + ' ' + unit),
      h(
        'button',
        { type: 'button', className: 'bh-stepper-btn', 'aria-label': 'Thêm một ' + unit, disabled: value >= max, onClick: function () { set(value + 1); } },
        h(Icon, { name: 'plus' })
      )
    );
  }

  window.BepHoaLac = Object.assign(window.BepHoaLac || {}, {
    Button: Button,
    Chip: Chip,
    SearchField: SearchField,
    AvailabilityBadge: AvailabilityBadge,
    RecipeCard: RecipeCard,
    BottomNav: BottomNav,
    EmptyState: EmptyState,
    StepTimer: StepTimer,
    ServingStepper: ServingStepper,
    Icon: Icon
  });
})();
