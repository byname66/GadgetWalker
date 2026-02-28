/**
 * @name GadgetWalker
 * @description GadgetWalker
 * @kind path-problem
 * @problem.severity error
 * @id java/edges-source-sink-path
 * @tags security
 */

import java
import source
import sink

query predicate edges(Method a, Method b) {
  a.polyCalls(b)
}

from
  Source sourceMethod,      
  AnySink sinkMethod        
where
  edges+(sourceMethod, sinkMethod)

select
  sinkMethod,
  sourceMethod,
  sinkMethod,
  "Found a path from $@ to $@.",
  sourceMethod, sourceMethod.getDeclaringType().getName() + "." + sourceMethod.getName(),
  sinkMethod, sinkMethod.getDeclaringType().getName() + "." + sinkMethod.getName()
 