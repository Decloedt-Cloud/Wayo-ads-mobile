import org.jetbrains.kotlin.gradle.dsl.KotlinVersion
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

// Classpath so this script can reference [KotlinCompile] (overrides plugin defaults such as Sentry’s Kotlin 1.6).
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.2.20")
    }
}

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

    // Sentry (and some older plugins) still set Kotlin languageVersion 1.6, which recent compilers reject.
    afterEvaluate {
        tasks.withType<KotlinCompile>().configureEach {
            compilerOptions {
                languageVersion.set(KotlinVersion.KOTLIN_1_8)
                apiVersion.set(KotlinVersion.KOTLIN_1_8)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
