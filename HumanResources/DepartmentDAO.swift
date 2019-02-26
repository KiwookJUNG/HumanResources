//
//  DepartmentDAO.swift
//  HumanResources
//
//  Created by 정기욱 on 26/02/2019.
//  Copyright © 2019 Kiwook. All rights reserved.
//

import Foundation

class DepartmentDAO {
    // 부서 정보를 담을 튜플 타입 정의
    typealias DepartRecord = (Int, String, String)
    
    // SQLite 연결 및 초기화
    lazy var fmdb : FMDatabase! = { // 지연 저장 프로퍼티는 실제로 참조되기 전까지는 초기화 되지 않으며
        // 초기화를 위한 클로저 구문 역시 fmdb 변수가 초기화되는 시점에 최초 한 번만 실행됩니다.
        
        // 1. 파일 매니저 객체를 생성
        // 파일을 읽어들일 때에 파일 매니저 객체 사용
        // 파일을 단순이 읽기만 하는 것이 아니라 파일 존재 여부를 체크하고 파일을 복사해 주는 등의 기능 제공
        let fileMgr = FileManager.default
        
        // 2. 샌드박스 내 문서 디렉터리에서 데이터베이스 파일 경로를 확인
        // 반환되는 값은 URL 객체 배열이다.
        let docPath = fileMgr.urls(for: .documentDirectory, in: .userDomainMask).first
        let dbPath = docPath!.appendingPathComponent("hr.sqlite").path
        
        // 3. 샌드박스 경로에 파일이 없다면 메인 번들에 만들어 둔 hr.sqlite를 가져와 복사
        // 만약 경로상 파일이 없는 것으로 확인될 경우에 메인 번들에 반들어 둔 hr.sqlite 파일을 문서 디렉터리로
        // 복사한다.
        if fileMgr.fileExists(atPath: dbPath) == false {
            let dbSource = Bundle.main.path(forResource: "hr", ofType: "sqlite")
            try! fileMgr.copyItem(atPath: dbSource!, toPath: dbPath)
        }
        
        // 4. 준비된 데이터베이스 파일을 바탕으로 FMDatabase 객체를 생성
        
        let db = FMDatabase(path: dbPath)
        return db
    }()
    
    // DepartmentDAO 클래스의 생성자와 소멸자를 정의하고, 각각의 메소드 내부에서 데이터베이스 연결을 열고 닫는 코드를 작성
    init() {
        self.fmdb.open()
    }
    
    deinit {
        self.fmdb.close()
    }
    
    // department 테이블로부터 부서 목록을 읽어올 메소드 find를 정의한다.
    func find() -> [DepartRecord] {
        // 반환할 데이터를 담을 [DepartRecord] 타입의 객체 정의
        var departList = [DepartRecord]()
        
        do {
            // 1. 부서 정보 목록을 가져올 SQL 작성 및 쿼리 실행
            let sql = """
              SELECT depart_cd, depart_title, depart_addr
              FROM department
              ORDER BY depart_cd ASC
            """
            
            let rs = try self.fmdb.executeQuery(sql, values: nil)
            
            // 2. 결과 집합 추출
            while rs.next() {
                let departCd = rs.int(forColumn: "depart_cd")
                let departTitle = rs.string(forColumn: "depart_title")
                let departAddr = rs.string(forColumn: "depart_addr")
                
                // append 메소드 호출 시 아래 튜플을 괄호 없이 사용하지 않도록 주의
                departList.append( ( Int(departCd), departTitle!, departAddr! ) )
               }
            } catch let error as NSError {
                print("failed: \(error.localizedDescription)")
            }
        }
    
    func get(departCd: Int) -> DepartRecord? {
        // 1. 질의 실행
        let sql = """
        SELECT depart_cd, depart_title, depart_addr
        FROM department
        WHERE depart_cd = ?
        """
        
        let rs = self.fmdb.executeQuery(sql, withArgumentsIn: [departCd])
        
        // 결과 집합 처리
        if let _rs = rs { // 결과 집합이 옵셔널 타입으로 반환되므로, 이를 일반 상수에 바인딩하여 해제한다.
            _rs.next()
            
            let departId = _rs.int(forColumn: "depart_cd")
            let departTitle = _rs.string(forColumn: "depart_title")
            let departAddr = _rs.string(forColumn: "depart_addr")
            
            return ( Int(departId), departTitle!, departAddr! )
            
        } else { // 결과 집합이 없을 경우 nil을 반환한다.
            return nil
        }
    }
    
    func create(title: String!, addr: String!) -> Bool {
        do {
            let sql = """
                INSERT INTO department (depart_title, depart_addr)
                VALUES ( ? , ? )
            """
            try self.fmdb.executeUpdate(sql, values: [title, addr])
            return true
        } catch let error as NSError {
            print("Insert Error : \(error.localizedDescription)")
            return false
        }
    }
    
    func remove(departCd: Int) -> Bool {
        do {
            let sql = "DELETE FROM department WHERE depart_cd= ? "
            try self.fmdb.executeUpdate(sql, values: [departCd])
            return true
        } catch let error as NSError {
            print("DELETE Error : \(error.localizedDescription)")
            return false
        }
    }
}
