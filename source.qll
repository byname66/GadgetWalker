import java


/**
 * Serializable 接口方法
 */
class SerializableMethods extends Callable {
    SerializableMethods() {
        this.getName() in ["readObject", "readObjectNoData"] and
        exists(RefType rt |
            rt.getQualifiedName() = "java.io.Serializable" and
            rt = this.getDeclaringType().getASupertype*()
        )
    }
}

/**
 * equals() 方法源点
 */
class Equals extends Callable {
    Equals() {
        this.getName() = "equals" and
        this instanceof Method and
        exists(Parameter p |
            p = this.(Method).getParameter(0) and
            p.getType().(RefType).getQualifiedName() = "java.lang.Object"
        )
    }
}

/**
 * hashCode() 方法源点
 */
class HashCode extends Callable {
    HashCode() {
        this.getName() = "hashCode"
    }
}

/**
 * compareTo() 方法源点
 */
class Compare extends Callable {
    Compare() {
        this.getName() = "compare"
    }
}

/**
 * Externalizable 接口方法
 */
class ExternalizableMethod extends Callable {
    ExternalizableMethod() {
        this.getName() = "readExternal" and
        exists(RefType rt |
            rt = this.getDeclaringType().getASupertype*() and
            rt.getQualifiedName() = "java.io.Externalizable"
        )
    }
}


/**
 * InvocationHandler 接口方法
 */
class InvocationHandlerMethod extends Callable {
    InvocationHandlerMethod() {
        this.getName() = "invoke" and
        exists(RefType rt |
            rt = this.getDeclaringType().getASupertype*() and
            rt.getQualifiedName() = "java.lang.reflect.InvocationHandler"
        )
    }
}


/**
 * Groovy 相关方法源点
 */
class GroovyMethod extends Callable {
    GroovyMethod() {
        this.getDeclaringType().getQualifiedName() = "groovy.lang.GroovyObject" or
        this.getDeclaringType().getPackage().getName().matches("groovy.%")
    }
}

//Source定义为：1.类的readObject等反序列化方法  2.如equals/hashCode/compare等能接上已知链的方法(hashMap#key.hashCode / hashtable#key.equals / PriorityQueue#compare )
class Source extends Callable{
    Source(){
        exists(RefType rt |
            rt.getQualifiedName() = "java.io.Serializable" and
            rt = this.getDeclaringType().getASupertype*()
        ) and (
            this instanceof SerializableMethods or
            this instanceof Equals or
            this instanceof HashCode or
            this instanceof Compare or
            this instanceof ExternalizableMethod or
            this instanceof InvocationHandlerMethod or
            this instanceof GroovyMethod
        )
    }
}
