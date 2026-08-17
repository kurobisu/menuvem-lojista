pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            val propFile = file("local.properties")
            propFile.inputStream().use { properties.load(it) }

            // O usuário do Windows desta máquina é "Usuário" (com acento) e o
            // Gradle/AGP quebra com esse caminho. Reescrevemos para o nome curto
            // 8.3 (USURIO~2). O Flutter regenera local.properties a cada build,
            // então esta correção precisa rodar no início de todo build — é por
            // isso que ela vive aqui e não no arquivo. Mesma abordagem do projeto
            // CofreNuvem, que builda sem erros nesta máquina.
            fun temAcento(v: String?) =
                v != null && (v.contains("Usuário") || v.contains("Usurio") || v.contains("UsuÃ¡rio"))

            var corrigido = false

            var flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            if (temAcento(flutterSdkPath)) {
                flutterSdkPath = """C:\Users\USURIO~2\flutter"""
                properties.setProperty("flutter.sdk", flutterSdkPath)
                corrigido = true
            }

            if (temAcento(properties.getProperty("sdk.dir"))) {
                properties.setProperty("sdk.dir", """C:\Users\USURIO~2\AppData\Local\Android\Sdk""")
                corrigido = true
            }

            if (corrigido) {
                propFile.outputStream().use {
                    properties.store(it, "Caminhos corrigidos por settings.gradle.kts (usuario com acento)")
                }
            }

            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")
