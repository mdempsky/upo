functor Make(M : sig
                 val addon : CalendarAddons.t []
                 val whoami : transaction (option string)
             end) = struct
    open M

    type a = {Calendar : FullCalendar.t,
              Entries : list CalendarAddons.event_data}

    val create =
        uo <- whoami;
        entries <- CalendarAddons.extraEvents addon uo;
        tm <- now;
        cal <- FullCalendar.create {DefaultDate = case List.foldl (fn ev tmo => Some (case tmo of
                                                                                          None => ev.Start
                                                                                        | Some tm => min ev.Start tm)) None entries of
                                                      None => Some tm
                                                    | Some tm' => Some (max tm tm'),
                                    AllDaySlot = False,
                                    Content = None,
                                    OnSelect = None,
                                    OnDrop = None};
        return {Calendar = cal, Entries = entries}

    fun onload self =
        List.app (fn ev =>
                     Monad.ignore (FullCalendar.addEvent self.Calendar
                                                         {Id = ev.Id,
                                                          AllDay = False,
                                                          Start = ev.Start,
                                                          End = None,
                                                          Title = ev.Title,
                                                          Rendering = if ev.Background then
                                                                          FullCalendar.Background
                                                                      else
                                                                          FullCalendar.Normal,
                                                          TextColor = Option.mp (fn c => return (Some c)) ev.TextColor,
                                                          BackgroundColor = Option.mp (fn c => return (Some c)) ev.BackgroundColor})) self.Entries

    fun render ctx self = <xml>
      {CalendarAddons.aboveCalendar addon ctx self.Calendar}
      {FullCalendar.render self.Calendar}
    </xml>

    fun notification _ _ = <xml></xml>

    val ui = {Create = create,
              Onload = onload,
              Render = render,
              Notification = notification}
end
