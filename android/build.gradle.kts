allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// The Android lint "vital" release check crashes on JDK 17 inside plugin
// modules (lint calls the Java 21 API List.removeLast()). Skip only those
// tasks; flutter analyze/test remain the quality gates. Remove once the build
// runs on JDK 21+.
subprojects {
    tasks.matching { it.name.startsWith("lintVital") }.configureEach {
        enabled = false
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
