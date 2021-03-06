Date::DATE_FORMATS.merge!(
  :short_month_day => "%b %d",
  :month_year => "%B %Y",
  :day_date   => "%A %d",
  :wday_and_pretty_date => lambda { |time| time.strftime("%A, %B #{time.day.ordinalize}") },
  :abbrev_month_day => "%b. %-d",

  # "Friday, April 22nd, 2011"
  :formal => lambda { |time| time.strftime("%A, %B #{time.day.ordinalize}, %Y") },

  :pretty     => "%A, %B %d, %Y",
  :ymd        => "%Y/%m/%d",
  :ymd_no_formatting => "%Y%m%d",
  :default    => "%m/%d/%Y",
  :mdy_short_year => "%m/%d/%y",
  :db_year    => "%Y-%m-%d",
  :year_month => "%Y/%m",
  :short_ordinal => lambda { |time| time.strftime("%B #{time.day.ordinalize}, %Y") },
  :shorter_ordinal => lambda { |time| time.strftime("%b #{time.day.ordinalize}, %Y") }
)

Time::DATE_FORMATS.merge!(
  :underscored_iso_date_then_time => '%Y_%m_%d_%H_%M_%S',
  :HMS_Z => "%H-%M-%S_%Z",
  :time_then_date => lambda { |time| time.strftime("%I:%M %p, on %A, %B #{time.day.ordinalize}, %Y") },
  :short_date_then_time => "%m/%d/%Y at %I:%M %p",
  :mdy_short_year_then_time => "%m/%d/%y at %I:%M %p",
  :time_only => "%I:%M %p",

  # "Friday, April 22nd, 2011 at 1:30 PM"
  :formal_with_time => lambda { |time| time.strftime("%A, %B #{time.day.ordinalize}, %Y at %I:%M %p") }
)
