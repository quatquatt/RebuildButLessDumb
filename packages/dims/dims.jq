def prettify: {
  "attrset": {
    "lookups": .nrLookups,
    "merges": .nrOpUpdates,
    "mergeCopies": .nrOpUpdateValuesCopied
  },
  "list": {
    "concats": .list.concats,
  },
  "parser": {
    expressions: .nrExprs
  },
  "memoryBytes": {
    "envs": .envs.bytes,
    "list": .list.bytes,
    "sets": .sets.bytes,
    "symbols": .symbols.bytes,
    "values": .values.bytes,
    "total": .envs.bytes + .list.bytes + .sets.bytes + .symbols.bytes + .values.bytes
  },
  "speed": {
    "primops": .nrPrimOpCalls,
    "functionCalls": .nrFunctionCalls,
    "thunksMade": .nrThunks,
    "thunksAvoided": .nrAvoided,
  }
};

def display_number:
if . == 0 then
  null
else
  if . > 0 then
    "+" + (. | tostring) + "%"
  else
    (. | tostring) + "%"
  end
end;

def percentage(places):
  # Round to the nearest n decimal places (after the decimal place)
  . * pow(10; places + 2) | round / pow(10; places) | tostring;

def display_percentage:
  if . == 0 then
    null
  else
    if . > 0 then
      "+" + (. | percentage(2)) + "%"
    else
      (. | percentage(2)) + "%"
    end
  end;


[(.[] | prettify)] as [$stats_before, $stats_after] |
reduce ($stats_before | paths(numbers)) as $path (
  $stats_after;
    setpath(
      $path;
      getpath($path) as $after |
      ($stats_before | getpath($path)) as $before |
      if $before == 0 then
        false
      else
        (($after - $before) / $before) | display_percentage
      end
    )
)
