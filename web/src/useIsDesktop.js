import { useEffect, useState } from "react";

// True on big screens. Phone layout is used below the breakpoint, the split
// two-pane layout above it.
export function useIsDesktop(query = "(min-width: 900px)") {
  const get = () =>
    typeof window !== "undefined" && window.matchMedia(query).matches;
  const [isDesktop, setIsDesktop] = useState(get);
  useEffect(() => {
    const mq = window.matchMedia(query);
    const handler = () => setIsDesktop(mq.matches);
    handler();
    mq.addEventListener("change", handler);
    return () => mq.removeEventListener("change", handler);
  }, [query]);
  return isDesktop;
}
