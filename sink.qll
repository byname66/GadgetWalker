import java

/**
 * 判断类型是否实现了 Serializable 接口
 */
predicate implementsSerializable(RefType rt) {
  exists(RefType superRt |
    superRt.getQualifiedName() = "java.io.Serializable" and
    superRt = rt.getASupertype*()
  )
}

/**
 * 判断一个 RefType 是否为 Expression 类型
 * 包名匹配条件：
 *   - javax.el.* 或 jakarta.el.* (标准 EL 包)
 *   - *.el.* (其他 EL 实现，如 org.apache.el)
 *   - *.ognl.* (OGNL 表达式)
 *   - *.expression.* (通用表达式包)
 */
predicate isExpressionType(RefType rt) {
  rt.getName().matches("%Expression%") and
  rt.getName() != "LambdaExpression" and
  (
    rt.getQualifiedName().matches("javax.el.%") or
    rt.getQualifiedName().matches("jakarta.el.%") or
    rt.getQualifiedName().matches("%.el.%") or
    rt.getQualifiedName().matches("%.ognl.%") or
    rt.getQualifiedName().matches("%.expression.%")
  )
}

/**
 * 判断方法的声明类型是否匹配指定的类名
 */
predicate isDeclaringTypeOf(Method m, string qn) {
  exists(RefType rt |
    rt = m.getDeclaringType() and
    (
      rt.getQualifiedName() = qn or
      rt.getName() = qn or
      exists(RefType superRt |
        superRt = rt.getASupertype*() and
        (superRt.getQualifiedName() = qn or superRt.getName() = qn)
      )
    )
  )
}

class AnySink extends Method {
  AnySink() {
    (
      this instanceof JndiLookupSink or
      this instanceof DataSourceGetConnectionSink or
      this instanceof RuntimeExecSink or
      this instanceof ExpressionGetValueSink
    ) and
    implementsSerializable(this.getDeclaringType().(RefType))
  }

  /**
   * 获取匹配到的方法信息（格式：全限定类名.方法名）
   */
  string getMatchedMethod() {
    result = this.getDeclaringType().(RefType).getQualifiedName() + "." + this.getName()
  }
}

class JndiLookupSink extends Method {
  JndiLookupSink() {
    this.getName() = "lookup" and
    isDeclaringTypeOf(this, "javax.naming.Context")
  }
}

class DataSourceGetConnectionSink extends Method {
  DataSourceGetConnectionSink() {
    this.getName() = "getConnection" and
    isDeclaringTypeOf(this, "javax.sql.DataSource")
  }
}

class RuntimeExecSink extends Method {
  RuntimeExecSink() {
    this.getName() = "exec" and
    isDeclaringTypeOf(this, "java.lang.Runtime")
  }
}

/**
 * 逻辑说明：
 * 1. 匹配**包含** getValue 或 findValue 方法调用的方法
 * 2. 被调用的 getValue/findValue 方法的声明类型必须是 Expression 类型
 * 3. receiver (qualifier) 必须是字段访问
 * 4. 该字段的类型也必须是 Expression 类型
 * 5. 该字段必须是此方法所在类的成员变量
 */
class ExpressionGetValueSink extends Method {
  ExpressionGetValueSink() {
    exists(MethodCall mc, RefType expressionType, FieldAccess fa |
      // 方法调用 mc 在 this 方法内部
      mc.getEnclosingCallable() = this and
      (mc.getMethod().getName() = "getValue" or mc.getMethod().getName() = "findValue") and
      // 被调用的方法的声明类型是 Expression 类型
      expressionType = mc.getMethod().getDeclaringType().(RefType) and
      isExpressionType(expressionType) and
      // receiver (qualifier) 是一个字段访问
      fa = mc.getQualifier() and
      isExpressionType(fa.getField().getType().(RefType)) and
      fa.getField().getDeclaringType() = this.getDeclaringType()
    )
  }

  /**
   * 获取包含此 Expression 字段的类名
   */
  string getDeclaringClassName() {
    exists(FieldAccess fa, MethodCall mc |
      mc.getEnclosingCallable() = this and
      fa = mc.getQualifier() and
      result = fa.getField().getDeclaringType().getQualifiedName()
    )
  }

  /**
   * 获取 Expression 字段名
   */
  string getFieldName() {
    exists(FieldAccess fa, MethodCall mc |
      mc.getEnclosingCallable() = this and
      fa = mc.getQualifier() and
      result = fa.getField().getName()
    )
  }
}

