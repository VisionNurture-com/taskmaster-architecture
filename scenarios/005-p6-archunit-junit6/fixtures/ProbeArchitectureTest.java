package com.example.taskmaster.presentation;

import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

// 測定用のルール 1 本（記事には載せない）。エンジンがテストを見つけるかだけを確かめる
@AnalyzeClasses(packages = "com.example.taskmaster")
class ProbeArchitectureTest {

    @ArchTest
    static final ArchRule presentationDoesNotUseInfrastructure =
            noClasses().that().resideInAPackage("..presentation..")
                    .should().dependOnClassesThat().resideInAPackage("..infrastructure..");
}
